class Om::WaitingOrdersController < Om::BaseController
  DATE_TYPE_FALLBACK_MAP = {
    "CREATE" => :create_time,
    "CREATE_TIME" => :create_time,
    "APTD" => :aptd_req_ymd,
    "APTD_REQ_YMD" => :aptd_req_ymd
  }.freeze
  WAITING_WORK_STATUS_CODES = %w[WAIT WAITING READY].freeze

  def index
    @search_form = build_search_form

    respond_to do |format|
      format.html
      format.json do
        status_map = order_status_name_map
        render json: waiting_order_scope.map { |order| master_row_json(order, status_map) }
      end
    end
  end

  def details
    order = find_order_by_id_param
    render json: detail_rows_for(order)
  rescue ActiveRecord::RecordNotFound
    render json: [], status: :not_found
  end

  def batch_save
    operations = batch_save_params
    result = { updated: 0 }
    errors = []

    ActiveRecord::Base.transaction do
      Array(operations[:rowsToUpdate]).each do |attrs|
        apply_detail_distribution(attrs, result, errors)
      end

      if errors.any?
        raise ActiveRecord::Rollback
      end
    end

    if errors.any?
      render json: { success: false, errors: errors.uniq }, status: :unprocessable_entity
    else
      render json: { success: true, message: "오더분배 정보가 저장되었습니다.", data: result }
    end
  end

  private
    def menu_code_for_permission
      "OM_WAITING_ORD"
    end

    def search_params
      params.fetch(:q, {}).permit(:cust_cd, :cust_nm, :date_type, :start_date, :end_date)
    end

    def batch_save_params
      params.permit(
        rowsToDelete: [],
        rowsToInsert: detail_permitted_fields,
        rowsToUpdate: detail_permitted_fields
      )
    end

    def detail_permitted_fields
      %i[
        ord_no
        seq
        item_cd
        div_qty
        div_wgt
        div_vol
      ]
    end

    def search_form
      @search_form
    end

    def build_search_form
      form = Om::WaitingOrderSearchForm.new(search_params.to_h)
      today = Time.zone.today
      month_start = today.beginning_of_month
      month_end = today.end_of_month

      if form.start_date.blank?
        form.start_date = today
      end
      if form.end_date.blank?
        form.end_date = today
      end

      if form.start_date < month_start
        form.start_date = month_start
      end
      if form.end_date > month_end
        form.end_date = month_end
      end
      if form.end_date < form.start_date
        form.end_date = form.start_date
      end

      form.cust_cd = form.cust_cd.to_s.strip.upcase
      if form.cust_nm.blank? && form.cust_cd.present?
        form.cust_nm = customer_name_for(form.cust_cd)
      end

      normalized_date_type = form.date_type.to_s.strip.upcase
      if valid_date_type_code?(normalized_date_type)
        form.date_type = normalized_date_type
      else
        form.date_type = default_date_type_code
      end

      form
    end

    def waiting_order_scope
      scope = OmOrder.active.where(ord_cmpt_dtm: nil)
      scope = scope.where("COALESCE(work_stat_cd, '') = '' OR UPPER(work_stat_cd) IN (?)", WAITING_WORK_STATUS_CODES)

      if search_form.cust_cd.present?
        scope = scope.where(cust_cd: search_form.cust_cd)
      end

      date_column = date_column_for(search_form.date_type)
      if date_column == :aptd_req_ymd
        scope = scope.where(aptd_req_ymd: search_form.start_date..search_form.end_date)
      else
        scope = scope.where(create_time: search_form.start_date.beginning_of_day..search_form.end_date.end_of_day)
      end

      scope.order(create_time: :desc, ord_no: :desc)
    end

    def master_row_json(order, status_map)
      {
        id: order.ord_no,
        ord_no: order.ord_no,
        ord_stat_cd: order.ord_stat_cd,
        ord_stat_nm: status_map[order.ord_stat_cd.to_s.upcase].presence || order.ord_stat_cd.to_s,
        ord_type_cd: order.ord_type_cd,
        ord_type_nm: order.ord_type_nm.to_s.presence || order.ord_type_cd.to_s,
        create_time: order.create_time&.strftime("%Y-%m-%d %H:%M:%S"),
        aptd_req_ymd: order.aptd_req_ymd&.strftime("%Y-%m-%d"),
        chg_aptd_ymd: order.aptd_req_ymd&.strftime("%Y-%m-%d"),
        dpt_ar_cd: order.dpt_ar_cd,
        dpt_ar_nm: order.dpt_ar_nm,
        arv_ar_cd: order.arv_ar_cd,
        arv_ar_nm: order.arv_ar_nm,
        cust_cd: order.cust_cd,
        cust_nm: order.cust_nm
      }
    end

    def detail_rows_for(order)
      completed = distribution_totals_for(order)

      ord_qty = numeric_value(order.ord_qty)
      ord_wgt = numeric_value(order.ord_wgt)
      ord_vol = numeric_value(order.ord_vol)

      rem_qty = clamp_to_zero(ord_qty - completed[:qty])
      rem_wgt = clamp_to_zero(ord_wgt - completed[:wgt])
      rem_vol = clamp_to_zero(ord_vol - completed[:vol])

      basis_unit_code = basis_unit_code_for(order)

      [
        {
          ord_no: order.ord_no,
          seq: 1,
          item_cd: order.item_cd,
          item_nm: order.item_nm,
          basis_unit_clas_cd: basis_unit_code,
          ord_qty: ord_qty,
          ord_wgt: ord_wgt,
          ord_vol: ord_vol,
          div_cmpt_qty: completed[:qty],
          div_cmpt_wgt: completed[:wgt],
          div_cmpt_vol: completed[:vol],
          avail_stock_qty: rem_qty,
          avail_stock_wgt: rem_wgt,
          avail_stock_vol: rem_vol,
          div_qty: 0,
          div_wgt: 0,
          div_vol: 0,
          balance_qty: rem_qty,
          balance_wgt: rem_wgt,
          balance_vol: rem_vol
        }
      ]
    end

    def apply_detail_distribution(attrs, result, errors)
      ord_no = attrs[:ord_no].to_s.strip.upcase
      if ord_no.blank?
        errors << "오더번호가 없습니다."
        return
      end

      order = OmOrder.find_by(ord_no: ord_no)
      if order.nil?
        errors << "오더를 찾을 수 없습니다: #{ord_no}"
        return
      end

      div_qty = numeric_decimal(attrs[:div_qty])
      div_wgt = numeric_decimal(attrs[:div_wgt])
      div_vol = numeric_decimal(attrs[:div_vol])

      if div_qty.negative? || div_wgt.negative? || div_vol.negative?
        errors << "분배 수량/중량/부피는 0 이상이어야 합니다: #{ord_no}"
        return
      end

      if div_qty.zero? && div_wgt.zero? && div_vol.zero?
        return
      end

      completed = distribution_totals_for(order)
      rem_qty = clamp_to_zero(numeric_decimal(order.ord_qty) - completed_decimal(completed[:qty]))
      rem_wgt = clamp_to_zero(numeric_decimal(order.ord_wgt) - completed_decimal(completed[:wgt]))
      rem_vol = clamp_to_zero(numeric_decimal(order.ord_vol) - completed_decimal(completed[:vol]))

      if div_qty > rem_qty || div_wgt > rem_wgt || div_vol > rem_vol
        errors << "분배값이 잔여량 또는 가용재고량을 초과할 수 없습니다: #{ord_no}"
        return
      end

      work_route = find_or_create_work_route_for(order)
      work_route_result = OmWorkRouteResult.find_or_initialize_by(
        work_route_no: work_route.work_route_no,
        ord_no: order.ord_no
      )

      now = Time.current
      actor = current_actor
      if work_route_result.new_record?
        work_route_result.create_by = actor
        work_route_result.create_time = now
      end

      work_route_result.update_by = actor
      work_route_result.update_time = now
      work_route_result.use_yn = "Y"
      work_route_result.rslt_yn = "N" if work_route_result.rslt_yn.to_s.strip.blank?
      work_route_result.rslt_qty = (numeric_decimal(work_route_result.rslt_qty) + div_qty).round(3)
      work_route_result.rslt_wgt = (numeric_decimal(work_route_result.rslt_wgt) + div_wgt).round(3)
      work_route_result.rslt_vol = (numeric_decimal(work_route_result.rslt_vol) + div_vol).round(3)
      work_route_result.save!

      result[:updated] += 1
    rescue ActiveRecord::ActiveRecordError => e
      errors << "오더분배 저장 중 오류가 발생했습니다(#{ord_no}): #{e.message}"
    end

    def find_or_create_work_route_for(order)
      route = OmWorkRoute.where(ord_no: order.ord_no).order(:id).first

      if route.nil?
        now = Time.current
        actor = current_actor
        route = OmWorkRoute.new(
          ord_no: order.ord_no,
          work_route_no: generated_work_route_no,
          work_route_nm: "대기오더분배",
          dpt_ar_nm: order.dpt_ar_nm,
          arv_ar_nm: order.arv_ar_nm,
          ord_vol: order.ord_vol,
          use_yn: "Y",
          create_by: actor,
          create_time: now,
          update_by: actor,
          update_time: now
        )
        route.save!
      end

      route
    end

    def distribution_totals_for(order)
      scope = OmWorkRouteResult.where(ord_no: order.ord_no)
      {
        qty: numeric_value(scope.sum(:rslt_qty)),
        wgt: numeric_value(scope.sum(:rslt_wgt)),
        vol: numeric_value(scope.sum(:rslt_vol))
      }
    end

    def find_order_by_id_param
      raw = params[:id].to_s.strip.upcase
      order = OmOrder.find_by(ord_no: raw)
      if order.nil?
        raise ActiveRecord::RecordNotFound
      end

      order
    end

    def order_status_name_map
      if !defined?(AdmCodeDetail) || !AdmCodeDetail.table_exists?
        return {}
      end

      AdmCodeDetail.where(code: "76", use_yn: "Y").ordered.pluck(:detail_code, :detail_code_name).to_h do |code, name|
        [ code.to_s.strip.upcase, name.to_s ]
      end
    rescue ActiveRecord::StatementInvalid
      {}
    end

    def date_type_field_map
      @date_type_field_map ||= begin
        if !defined?(AdmCodeDetail) || !AdmCodeDetail.table_exists?
          {}
        else
          map = {}
          AdmCodeDetail.where(code: "91", use_yn: "Y").ordered.pluck(:detail_code, :detail_code_name).each do |code, name|
            key = code.to_s.strip.upcase
            label = name.to_s
            if label.include?("생성")
              map[key] = :create_time
            elsif label.include?("납기") || label.include?("요청")
              map[key] = :aptd_req_ymd
            end
          end
          map
        end
      end
    rescue ActiveRecord::StatementInvalid
      {}
    end

    def valid_date_type_code?(code)
      all_codes = date_type_field_map.keys + DATE_TYPE_FALLBACK_MAP.keys
      all_codes.include?(code)
    end

    def default_date_type_code
      code = date_type_field_map.keys.first
      if code.present?
        code
      else
        "CREATE_TIME"
      end
    end

    def date_column_for(code)
      normalized = code.to_s.strip.upcase
      if date_type_field_map.key?(normalized)
        date_type_field_map[normalized]
      elsif DATE_TYPE_FALLBACK_MAP.key?(normalized)
        DATE_TYPE_FALLBACK_MAP[normalized]
      else
        :create_time
      end
    end

    def basis_unit_code_for(order)
      if !defined?(StdClientItemCode) || !StdClientItemCode.table_exists?
        return ""
      end

      item = StdClientItemCode.find_by(bzac_cd: order.cust_cd.to_s.strip.upcase, item_cd: order.item_cd.to_s.strip.upcase)
      item&.basis_unit_cd.to_s
    rescue ActiveRecord::StatementInvalid
      ""
    end

    def customer_name_for(cust_cd)
      if !defined?(StdBzacMst) || !StdBzacMst.table_exists?
        return cust_cd
      end

      StdBzacMst.find_by(bzac_cd: cust_cd.to_s.strip.upcase)&.bzac_nm.to_s.presence || cust_cd
    rescue ActiveRecord::StatementInvalid
      cust_cd
    end

    def generated_work_route_no
      "WR#{Time.current.strftime('%Y%m%d%H%M%S')}#{rand(1000..9999)}"
    end

    def current_actor
      if Current.user&.user_id_code.present?
        Current.user.user_id_code
      elsif Current.user&.email_address.present?
        Current.user.email_address
      else
        "system"
      end
    end

    def numeric_value(value)
      value.to_d.round(3).to_f
    end

    def numeric_decimal(value)
      if value.nil? || value == ""
        return 0.to_d
      end

      BigDecimal(value.to_s)
    rescue ArgumentError, TypeError
      0.to_d
    end

    def completed_decimal(value)
      BigDecimal(value.to_s)
    rescue ArgumentError, TypeError
      0.to_d
    end

    def clamp_to_zero(value)
      decimal = numeric_decimal(value)
      if decimal.negative?
        0.to_d
      else
        decimal.round(3).to_f
      end
    end
end
