class Om::PreOrderReceptionsController < Om::BaseController
  def index
    @search_form = build_search_form

    respond_to do |format|
      format.html
      format.json do
        rows = pre_order_receptions_scope.to_a
        order_no_map = latest_order_number_map(rows)
        render json: rows.each_with_index.map { |row, index| list_row_json(row, index + 1, order_no_map) }
      end
    end
  end

  def items
    render json: item_rows
  end

  def create_orders
    bef_ord_nos = selected_bef_order_numbers
    if bef_ord_nos.empty?
      render json: { success: false, message: "오더 생성 대상이 없습니다." }, status: :unprocessable_entity
      return
    end

    result = create_orders_now(bef_ord_nos)
    message = "#{result[:created].size}건 생성, #{result[:skipped].size}건 스킵되었습니다."
    render json: { success: true, message: message, data: result }
  rescue ActiveRecord::RecordInvalid => e
    render json: { success: false, message: e.record.errors.full_messages.join(", ") }, status: :unprocessable_entity
  rescue StandardError => e
    render json: { success: false, message: e.message }, status: :unprocessable_entity
  end

  private
    def menu_code_for_permission
      "OM_PRE_ORD_RECP"
    end

    def build_search_form
      form = Om::PreOrderReceptionSearchForm.new(search_params.to_h)

      if form.recp_start_ymd.blank?
        form.recp_start_ymd = Date.current.strftime("%Y-%m-%d")
      end
      if form.recp_end_ymd.blank?
        form.recp_end_ymd = Date.current.strftime("%Y-%m-%d")
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
        :bef_ord_no,
        :status_cd,
        :recp_start_ymd,
        :recp_end_ymd
      )
    end

    def pre_order_receptions_scope
      scope = OmPreOrderReception.active

      if search_cust_cd.present?
        scope = scope.where(cust_cd: search_cust_cd)
      end
      if search_cust_ord_no.present?
        scope = scope.where("cust_ord_no LIKE ?", "%#{search_cust_ord_no}%")
      end
      if search_bef_ord_no.present?
        scope = scope.where("bef_ord_no LIKE ?", "%#{search_bef_ord_no}%")
      end
      if search_status_cd.present?
        scope = scope.where(status_cd: search_status_cd)
      end

      scope = scope.where(create_time: search_date_range)
      scope.ordered
    end

    def list_row_json(row, recp_seq, order_no_map)
      {
        recp_seq: recp_seq,
        bef_ord_no: row.bef_ord_no,
        status_cd: row.status_cd,
        ord_stat_cd: row.status_cd,
        sctn_cd: nil,
        cust_ord_no: row.cust_ord_no,
        cust_cd: row.cust_cd,
        cust_nm: row.cust_nm,
        recp_ymd: row.create_time&.strftime("%Y-%m-%d"),
        aptd_req_ymd: nil,
        cust_ord_type_cd: nil,
        ord_kind_cd: nil,
        dpt_ar_cd: nil,
        arv_ar_cd: nil,
        ord_no: order_no_map[row.cust_ord_no.to_s.upcase],
        ord_type_cd: nil,
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
        item_nm: row.item_nm,
        qty: row.qty,
        wgt: row.wgt,
        vol: row.vol,
        update_time: row.update_time
      }
    end

    def latest_order_number_map(rows)
      cust_order_numbers = rows.map { |row| row.cust_ord_no.to_s.upcase }.reject(&:blank?).uniq
      if cust_order_numbers.empty?
        return {}
      end
      if !defined?(OmOrder) || !OmOrder.table_exists?
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

    def item_rows
      if !defined?(OmPreOrderReception) || !OmPreOrderReception.table_exists?
        return []
      end

      scope = OmPreOrderReception.active
      if item_search_cust_ord_no.present?
        scope = scope.where(cust_ord_no: item_search_cust_ord_no)
      elsif item_search_bef_ord_no.present?
        scope = scope.where(bef_ord_no: item_search_bef_ord_no)
      else
        return []
      end

      scope.order(:bef_ord_no, :item_cd, :id).to_a.each_with_index.map do |row, index|
        {
          line_no: index + 1,
          item_cd: row.item_cd,
          item_nm: row.item_nm,
          qty: row.qty,
          qty_unit_cd: nil,
          wgt: row.wgt,
          wgt_unit_cd: nil,
          vol: row.vol,
          vol_unit_cd: nil,
          bef_ord_no: row.bef_ord_no,
          cust_ord_no: row.cust_ord_no
        }
      end
    end

    def create_orders_now(bef_ord_nos)
      result = { created: [], skipped: [] }

      ActiveRecord::Base.transaction do
        receptions = OmPreOrderReception.active.where(bef_ord_no: bef_ord_nos).lock.order(:bef_ord_no).to_a
        if receptions.empty?
          raise ActiveRecord::RecordNotFound, "선택한 사전오더를 찾을 수 없습니다."
        end

        receptions.each do |reception|
          if reception.order_created?
            result[:skipped] << skip_payload(reception, "ALREADY_CREATED")
          else
            existing_order = find_existing_order(reception)
            if existing_order.present?
              mark_pre_order_created!(reception)
              result[:skipped] << skip_payload(reception, "ORDER_EXISTS", existing_order.ord_no)
            else
              order = OmOrder.new(order_params_from_pre_order(reception))
              order.save!
              mark_pre_order_created!(reception)
              result[:created] << { bef_ord_no: reception.bef_ord_no, ord_no: order.ord_no }
            end
          end
        end
      end

      result
    end

    def find_existing_order(reception)
      if !defined?(OmOrder) || !OmOrder.table_exists?
        return nil
      end

      scope = OmOrder.active
      if reception.cust_ord_no.present?
        scope = scope.where(cust_ord_no: reception.cust_ord_no)
      elsif reception.cust_cd.present?
        scope = scope.where(cust_cd: reception.cust_cd)
      else
        return nil
      end
      if reception.item_cd.present?
        scope = scope.where(item_cd: reception.item_cd)
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

    def skip_payload(reception, reason, ord_no = nil)
      payload = { bef_ord_no: reception.bef_ord_no, reason: reason }
      if ord_no.present?
        payload[:ord_no] = ord_no
      end
      payload
    end

    def selected_bef_order_numbers
      Array(params[:bef_ord_nos]).map { |value| value.to_s.strip.upcase }.reject(&:blank?).uniq
    end

    def search_cust_cd
      search_params[:cust_cd].to_s.strip.upcase.presence
    end

    def search_cust_ord_no
      search_params[:cust_ord_no].to_s.strip.upcase.presence
    end

    def search_bef_ord_no
      search_params[:bef_ord_no].to_s.strip.upcase.presence
    end

    def search_status_cd
      search_params[:status_cd].to_s.strip.upcase.presence
    end

    def search_recp_start_ymd
      search_params[:recp_start_ymd].to_s.strip.presence
    end

    def search_recp_end_ymd
      search_params[:recp_end_ymd].to_s.strip.presence
    end

    def item_search_cust_ord_no
      params[:cust_ord_no].to_s.strip.upcase.presence
    end

    def item_search_bef_ord_no
      params[:bef_ord_no].to_s.strip.upcase.presence
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

    def customer_name_for(cust_cd)
      if !defined?(StdBzacMst) || !StdBzacMst.table_exists?
        return cust_cd
      end

      StdBzacMst.find_by(bzac_cd: cust_cd.to_s.strip.upcase)&.bzac_nm.to_s.presence || cust_cd
    rescue ActiveRecord::StatementInvalid
      cust_cd
    end
end
