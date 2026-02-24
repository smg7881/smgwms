require "csv"

class Om::PreOrderReceptionErrorsController < Om::BaseController
  TEMPLATE_HEADERS = %w[cust_ord_no item_cd err_type_cd err_msg line_no].freeze

  def index
    @search_form = build_search_form

    respond_to do |format|
      format.html
      format.json do
        rows = pre_order_errors_scope.to_a
        reception_map = reception_map_from_errors(rows)
        order_no_map = order_no_map_from_errors(rows)

        render json: rows.each_with_index.map { |row, index| list_row_json(row, index + 1, reception_map, order_no_map) }
      end
    end
  end

  def items
    error = pre_order_errors_scope.find_by(id: params[:error_id].to_i)
    if error.blank?
      render json: []
      return
    end

    detail_rows = pre_order_errors_scope
      .where(upload_batch_no: error.upload_batch_no, cust_ord_no: error.cust_ord_no)
      .reorder(:line_no, :id)
      .to_a

    reception_map = reception_map_from_errors(detail_rows)
    render json: detail_rows.map { |row| detail_row_json(row, reception_map) }
  end

  def reprocess
    error_ids = selected_error_ids
    if error_ids.empty?
      render json: { success: false, message: "재처리 대상을 선택해 주세요." }, status: :unprocessable_entity
      return
    end

    result = reprocess_now(error_ids)
    message = "재처리 완료: 생성 #{result[:created].size}건, 스킵 #{result[:skipped].size}건, 실패 #{result[:failed].size}건"
    render json: { success: true, message: message, data: result }
  rescue ActiveRecord::RecordInvalid => e
    render json: { success: false, message: e.record.errors.full_messages.join(", ") }, status: :unprocessable_entity
  rescue StandardError => e
    render json: { success: false, message: e.message }, status: :unprocessable_entity
  end

  def download_template
    csv_body = CSV.generate(headers: TEMPLATE_HEADERS, write_headers: true) do |csv|
      csv << [ "SAMPLE-ORD-0001", "ITEM-0001", "E100", "필수 값 누락", "1" ]
    end

    send_data(
      "\uFEFF#{csv_body}",
      filename: "OM_beforeORDERErrorRegister.csv",
      type: "text/csv; charset=utf-8"
    )
  end

  def upload_template
    file = params[:file]
    if file.blank?
      render json: { success: false, message: "업로드 파일이 없습니다." }, status: :unprocessable_entity
      return
    end

    extension = File.extname(file.original_filename.to_s).downcase
    if extension != ".csv"
      render json: { success: false, message: "CSV 파일만 업로드할 수 있습니다." }, status: :unprocessable_entity
      return
    end

    result = import_csv_errors!(file)
    message = "오류 업로드 완료: 등록 #{result[:inserted]}건"
    if result[:errors].any?
      message = "#{message}, 실패 #{result[:errors].size}건"
    end

    render json: { success: true, message: message, data: result }
  rescue CSV::MalformedCSVError => e
    render json: { success: false, message: "CSV 파싱 실패: #{e.message}" }, status: :unprocessable_entity
  rescue StandardError => e
    render json: { success: false, message: e.message }, status: :unprocessable_entity
  end

  private
    def menu_code_for_permission
      "OM_PRE_ORD_ERR"
    end

    def build_search_form
      form = Om::PreOrderReceptionErrorSearchForm.new(search_params.to_h)

      if form.recp_start_ymd.blank?
        form.recp_start_ymd = Date.current.strftime("%Y-%m-%d")
      end
      if form.recp_end_ymd.blank?
        form.recp_end_ymd = Date.current.strftime("%Y-%m-%d")
      end
      if form.resolved_yn.blank?
        form.resolved_yn = "N"
      end
      if form.cust_cd.present?
        form.cust_nm = customer_name_for(form.cust_cd)
      end

      form
    end

    def search_params
      params.fetch(:q, {}).permit(
        :cust_cd,
        :cust_ord_no,
        :resolved_yn,
        :recp_start_ymd,
        :recp_end_ymd
      )
    end

    def search_cust_cd
      search_params[:cust_cd].to_s.strip.upcase.presence
    end

    def search_cust_ord_no
      search_params[:cust_ord_no].to_s.strip.upcase.presence
    end

    def search_resolved_yn
      normalized = search_params[:resolved_yn].to_s.strip.upcase
      if %w[Y N].include?(normalized)
        normalized
      else
        nil
      end
    end

    def search_recp_start_ymd
      search_params[:recp_start_ymd].to_s.strip.presence
    end

    def search_recp_end_ymd
      search_params[:recp_end_ymd].to_s.strip.presence
    end

    def search_date_range
      start_date = parse_date(search_recp_start_ymd) || Date.current
      end_date = parse_date(search_recp_end_ymd) || start_date

      if end_date < start_date
        start_date, end_date = end_date, start_date
      end

      start_date.beginning_of_day..end_date.end_of_day
    end

    def parse_date(value)
      if value.blank?
        return nil
      end

      Date.parse(value)
    rescue ArgumentError
      nil
    end

    def pre_order_errors_scope
      scope = OmPreOrderError.active
      scope = scope.where(create_time: search_date_range)

      if search_cust_ord_no.present?
        scope = scope.where("cust_ord_no LIKE ?", "%#{search_cust_ord_no}%")
      end
      if search_resolved_yn.present?
        scope = scope.where(resolved_yn: search_resolved_yn)
      end
      if search_cust_cd.present?
        scope = scope.where(cust_ord_no: customer_order_numbers_for(search_cust_cd))
      end

      scope.order(create_time: :desc, upload_batch_no: :desc, line_no: :asc, id: :asc)
    end

    def customer_order_numbers_for(cust_cd)
      OmPreOrderReception.active.where(cust_cd: cust_cd).pluck(:cust_ord_no).compact_blank.map(&:upcase)
    rescue ActiveRecord::StatementInvalid
      []
    end

    def reception_map_from_errors(errors)
      cust_order_numbers = errors.map { |row| row.cust_ord_no.to_s.upcase }.reject(&:blank?).uniq
      if cust_order_numbers.empty?
        return { by_order: {}, by_item: {} }
      end

      receptions = OmPreOrderReception.active.where(cust_ord_no: cust_order_numbers).to_a
      by_order = {}
      by_item = {}

      receptions.each do |row|
        cust_order_no = row.cust_ord_no.to_s.upcase
        item_code = row.item_cd.to_s.upcase

        if by_order[cust_order_no].blank?
          by_order[cust_order_no] = row
        end

        composite_key = "#{cust_order_no}::#{item_code}"
        if by_item[composite_key].blank?
          by_item[composite_key] = row
        end
      end

      { by_order: by_order, by_item: by_item }
    rescue ActiveRecord::StatementInvalid
      { by_order: {}, by_item: {} }
    end

    def order_no_map_from_errors(errors)
      cust_order_numbers = errors.map { |row| row.cust_ord_no.to_s.upcase }.reject(&:blank?).uniq
      if cust_order_numbers.empty?
        return {}
      end

      result = {}
      OmOrder.active.where(cust_ord_no: cust_order_numbers).ordered_recent.pluck(:cust_ord_no, :ord_no).each do |cust_ord_no, ord_no|
        key = cust_ord_no.to_s.upcase
        if result[key].blank?
          result[key] = ord_no
        end
      end
      result
    rescue ActiveRecord::StatementInvalid
      {}
    end

    def list_row_json(row, recp_seq, reception_map, order_no_map)
      reception = reception_for(row, reception_map)
      cust_order_no = row.cust_ord_no.to_s.upcase

      {
        id: row.id,
        recp_seq: recp_seq,
        sctn_cd: row.err_type_cd,
        msg_cd: row.err_type_cd,
        err_msg: row.err_msg,
        cust_ord_no: row.cust_ord_no,
        cust_cd: reception&.cust_cd,
        cust_nm: reception&.cust_nm,
        recp_ymd: row.create_time&.strftime("%Y-%m-%d"),
        aptd_req_ymd: nil,
        cust_ord_type_cd: nil,
        retrngd_yn: nil,
        dpt_ar_cd: nil,
        arv_ar_cd: nil,
        strt_ymd: nil,
        arv_ar_ofcr_nm: nil,
        arv_ar_ofcr_tel_no: nil,
        ord_req_cust_cd: nil,
        bilg_cust_cd: nil,
        cust_bzac_cd: nil,
        cust_ofcr_nm: nil,
        cust_ofcr_tel_no: nil,
        cargo_form_cd: nil,
        prcl: nil,
        item_cd: row.item_cd,
        qty: reception&.qty,
        wgt: reception&.wgt,
        vol: reception&.vol,
        line_no: row.line_no,
        upload_batch_no: row.upload_batch_no,
        resolved_yn: row.resolved_yn,
        ord_no: order_no_map[cust_order_no],
        update_time: row.update_time
      }
    end

    def detail_row_json(row, reception_map)
      reception = reception_for(row, reception_map)
      {
        line_no: row.line_no,
        msg: row.err_msg,
        item_cd: row.item_cd,
        qty: reception&.qty,
        qty_unit_cd: nil,
        wgt: reception&.wgt,
        wgt_unit_cd: nil,
        vol: reception&.vol,
        vol_unit_cd: nil
      }
    end

    def reception_for(error_row, reception_map)
      cust_order_no = error_row.cust_ord_no.to_s.upcase
      item_code = error_row.item_cd.to_s.upcase
      by_item_key = "#{cust_order_no}::#{item_code}"

      reception = reception_map[:by_item][by_item_key]
      if reception.present?
        return reception
      end

      reception_map[:by_order][cust_order_no]
    end

    def selected_error_ids
      Array(params[:error_ids]).map { |value| value.to_i }.select(&:positive?).uniq
    end

    def reprocess_now(error_ids)
      result = {
        created: [],
        skipped: [],
        failed: []
      }

      errors = OmPreOrderError.active.where(id: error_ids).order(:id).to_a
      grouped = errors.group_by { |row| row.cust_ord_no.to_s.upcase }

      grouped.each do |cust_order_no, grouped_errors|
        if cust_order_no.blank?
          result[:failed] << { cust_ord_no: nil, reason: "고객오더번호가 없습니다.", error_ids: grouped_errors.map(&:id) }
          next
        end

        begin
          ActiveRecord::Base.transaction do
            reception = OmPreOrderReception.active.find_by(cust_ord_no: cust_order_no)
            if reception.blank?
              raise ActiveRecord::RecordNotFound, "사전오더 데이터를 찾을 수 없습니다: #{cust_order_no}"
            end

            if reception.order_created?
              mark_errors_resolved!(grouped_errors)
              result[:skipped] << {
                cust_ord_no: cust_order_no,
                reason: "ALREADY_CREATED",
                count: grouped_errors.size
              }
              next
            end

            existing_order = find_existing_order(cust_order_no, reception.item_cd)
            if existing_order.present?
              mark_pre_order_created!(reception)
              mark_errors_resolved!(grouped_errors)
              result[:skipped] << {
                cust_ord_no: cust_order_no,
                reason: "ORDER_EXISTS",
                ord_no: existing_order.ord_no,
                count: grouped_errors.size
              }
              next
            end

            order = OmOrder.new(order_params_from_pre_order(reception))
            order.save!
            mark_pre_order_created!(reception)
            mark_errors_resolved!(grouped_errors)

            result[:created] << {
              cust_ord_no: cust_order_no,
              ord_no: order.ord_no,
              count: grouped_errors.size
            }
          end
        rescue StandardError => e
          result[:failed] << {
            cust_ord_no: cust_order_no,
            reason: e.message,
            error_ids: grouped_errors.map(&:id)
          }
        end
      end

      result
    end

    def find_existing_order(cust_ord_no, item_cd)
      scope = OmOrder.active.where(cust_ord_no: cust_ord_no)
      if item_cd.to_s.strip.present?
        scope = scope.where(item_cd: item_cd.to_s.strip.upcase)
      end
      scope.ordered_recent.first
    end

    def order_params_from_pre_order(reception)
      {
        ord_no: next_order_number,
        cust_cd: reception.cust_cd,
        cust_nm: reception.cust_nm,
        cust_ord_no: reception.cust_ord_no,
        item_cd: reception.item_cd,
        item_nm: reception.item_nm,
        ord_qty: reception.qty,
        ord_wgt: reception.wgt,
        ord_vol: reception.vol,
        ord_stat_cd: OmPreOrderReception::STATUS_ORDER_CREATED,
        ord_type_cd: "PRE_ORDER",
        ord_type_nm: "Pre Order",
        work_stat_cd: "WAITING",
        use_yn: "Y"
      }
    end

    def next_order_number
      10.times do
        candidate = "ORD#{Time.current.strftime('%Y%m%d%H%M%S')}#{SecureRandom.random_number(10_000).to_s.rjust(4, '0')}"
        if OmOrder.exists?(ord_no: candidate)
          next
        end
        return candidate
      end

      "ORD#{SecureRandom.hex(8).upcase}"
    end

    def mark_pre_order_created!(reception)
      reception.update!(status_cd: OmPreOrderReception::STATUS_ORDER_CREATED)
    end

    def mark_errors_resolved!(errors)
      errors.each do |row|
        row.update!(resolved_yn: "Y", use_yn: "N")
      end
    end

    def import_csv_errors!(file)
      raw_content = file.read
      utf8_content = raw_content.encode("UTF-8", invalid: :replace, undef: :replace, replace: "")
      csv = CSV.parse(utf8_content, headers: true)

      headers = csv.headers.to_a.map { |value| value.to_s.strip.downcase }
      missing_headers = TEMPLATE_HEADERS - headers
      if missing_headers.any?
        raise ArgumentError, "필수 헤더가 누락되었습니다: #{missing_headers.join(', ')}"
      end

      batch_no = next_upload_batch_no
      batch = OmPreOrderUploadBatch.new(
        upload_batch_no: batch_no,
        file_nm: file.original_filename.to_s,
        upload_stat_cd: "UPLOADED",
        error_cnt: 0,
        use_yn: "Y"
      )
      batch.save!

      inserted_count = 0
      error_messages = []

      csv.each_with_index do |row, index|
        line_index = index + 1
        payload = build_error_payload_from_csv_row(row, batch_no, line_index)

        error_row = OmPreOrderError.new(payload)
        if error_row.save
          inserted_count += 1
        else
          error_messages << "line #{line_index}: #{error_row.errors.full_messages.join(', ')}"
        end
      end

      status_code = if error_messages.empty?
        "COMPLETED"
      else
        "COMPLETED_WITH_ERRORS"
      end
      batch.update!(upload_stat_cd: status_code, error_cnt: inserted_count)

      {
        upload_batch_no: batch_no,
        inserted: inserted_count,
        errors: error_messages
      }
    end

    def build_error_payload_from_csv_row(row, batch_no, line_index)
      cust_order_no = row["cust_ord_no"].to_s.strip.upcase
      item_code = row["item_cd"].to_s.strip.upcase
      error_type_code = row["err_type_cd"].to_s.strip.upcase
      error_message = row["err_msg"].to_s.strip
      line_no = row["line_no"].to_s.strip

      {
        upload_batch_no: batch_no,
        line_no: line_no.present? ? line_no.to_i : line_index,
        cust_ord_no: cust_order_no,
        item_cd: item_code,
        err_type_cd: error_type_code,
        err_msg: error_message,
        resolved_yn: "N",
        use_yn: "Y"
      }
    end

    def next_upload_batch_no
      loop do
        candidate = "BATCH#{Time.current.strftime('%Y%m%d%H%M%S')}#{SecureRandom.random_number(1000).to_s.rjust(3, '0')}"
        if !OmPreOrderUploadBatch.exists?(upload_batch_no: candidate)
          return candidate
        end
      end
    end

    def customer_name_for(cust_cd)
      StdBzacMst.find_by(bzac_cd: cust_cd.to_s.strip.upcase)&.bzac_nm.to_s.presence || cust_cd
    rescue ActiveRecord::StatementInvalid
      cust_cd
    end
end
