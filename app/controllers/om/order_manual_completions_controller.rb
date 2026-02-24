class Om::OrderManualCompletionsController < Om::BaseController
  ORDER_DATE_TYPES = %w[create_time aptd_req_ymd].freeze

  def index
    @search_form = build_search_form

    respond_to do |format|
      format.html
      format.json do
        render json: manual_completion_scope.map { |order| list_row(order) }
      end
    end
  end

  def details
    ord_no = params[:id].to_s.strip.upcase
    order = OmOrder.find_by(ord_no: ord_no)

    if order.nil?
      render json: [], status: :not_found
      return
    end

    render json: detail_rows(order)
  end

  def complete
    reason = params[:reason].to_s.strip
    order_nos = normalized_order_nos

    if order_nos.empty?
      render json: { success: false, message: "수동완료할 오더를 선택하세요." }, status: :unprocessable_entity
      return
    end

    if reason.blank?
      render json: { success: false, message: "수동완료 사유를 입력하세요." }, status: :unprocessable_entity
      return
    end

    completed_order_nos = []
    failures = []
    order_map = OmOrder.where(ord_no: order_nos).index_by(&:ord_no)

    order_nos.each do |ord_no|
      order = order_map[ord_no]
      if order.nil?
        failures << { ord_no: ord_no, reason: "오더를 찾을 수 없습니다." }
        next
      end

      if !order.manual_completable?
        failures << { ord_no: ord_no, reason: "수동완료 대상 상태가 아닙니다." }
        next
      end

      begin
        order.manual_complete!(reason: reason)
        completed_order_nos << ord_no
      rescue ActiveRecord::ActiveRecordError => e
        failures << { ord_no: ord_no, reason: e.message }
      end
    end

    if failures.empty?
      render json: {
        success: true,
        message: "#{completed_order_nos.size}건의 오더를 수동완료 처리했습니다.",
        completed_order_nos: completed_order_nos
      }
    else
      render json: {
        success: false,
        message: "#{completed_order_nos.size}건 완료, #{failures.size}건 실패",
        completed_order_nos: completed_order_nos,
        failures: failures
      }, status: :unprocessable_entity
    end
  end

  private
    def menu_code_for_permission
      "OM_ORD_MANL_CMPT"
    end

    def search_params
      params.fetch(:q, {}).permit(:cust_cd, :cust_nm, :date_type, :start_date, :end_date, :ord_no)
    end

    def normalized_order_nos
      values = Array(params[:order_nos]).map { |value| value.to_s.strip.upcase }.reject(&:blank?)
      values.uniq
    end

    def build_search_form
      form = Om::OrderManualCompletionSearchForm.new(search_params.to_h)
      today = Time.zone.today
      month_start = today.beginning_of_month
      month_end = today.end_of_month

      if form.start_date.blank?
        form.start_date = month_start
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

      if !ORDER_DATE_TYPES.include?(form.date_type)
        form.date_type = "create_time"
      end

      normalized_cust_cd = form.cust_cd.to_s.strip.upcase
      form.cust_cd = normalized_cust_cd
      if form.cust_nm.blank? && normalized_cust_cd.present?
        form.cust_nm = customer_name_for(normalized_cust_cd)
      end

      form.ord_no = form.ord_no.to_s.strip.upcase
      form
    end

    def manual_completion_scope
      scope = OmOrder.manual_completion_candidates

      if search_form.cust_cd.present?
        scope = scope.where(cust_cd: search_form.cust_cd)
      end
      if search_form.ord_no.present?
        scope = scope.where("ord_no LIKE ?", "%#{search_form.ord_no}%")
      end

      start_date = search_form.start_date
      end_date = search_form.end_date
      if search_form.date_type == "aptd_req_ymd"
        scope = scope.where(aptd_req_ymd: start_date..end_date)
      else
        scope = scope.where(create_time: start_date.beginning_of_day..end_date.end_of_day)
      end

      scope.order(create_time: :desc, ord_no: :desc)
    end

    def search_form
      @search_form
    end

    def list_row(order)
      {
        id: order.ord_no,
        ord_no: order.ord_no,
        ord_stat_cd: order.ord_stat_cd,
        ord_stat_nm: order.ord_stat_cd,
        ord_type_nm: order.ord_type_nm.to_s.presence || order.ord_type_cd.to_s,
        create_time: order.create_time&.strftime("%Y-%m-%d %H:%M:%S"),
        aptd_req_ymd: order.aptd_req_ymd&.strftime("%Y-%m-%d"),
        dpt_ar_nm: order.dpt_ar_nm,
        arv_ar_nm: order.arv_ar_nm,
        cust_cd: order.cust_cd,
        cust_nm: order.cust_nm
      }
    end

    def detail_rows(order)
      rslt_scope = OmWorkRouteResult.where(ord_no: order.ord_no)
      rslt_qty = rslt_scope.sum(:rslt_qty)
      rslt_wgt = rslt_scope.sum(:rslt_wgt)
      rslt_vol = rslt_scope.sum(:rslt_vol)
      div_dgr_cnt = OmWorkRoute.where(ord_no: order.ord_no).count

      ord_qty = numeric_value(order.ord_qty)
      ord_wgt = numeric_value(order.ord_wgt)
      ord_vol = numeric_value(order.ord_vol)
      rslt_qty_value = numeric_value(rslt_qty)
      rslt_wgt_value = numeric_value(rslt_wgt)
      rslt_vol_value = numeric_value(rslt_vol)

      [
        {
          seq: 1,
          div_dgr_cnt: div_dgr_cnt,
          item_cd: order.item_cd,
          item_nm: order.item_nm,
          work_stat: order.work_stat_cd.to_s.presence || "작업중",
          ord_qty: ord_qty,
          ord_wgt: ord_wgt,
          ord_vol: ord_vol,
          rslt_qty: rslt_qty_value,
          rslt_wgt: rslt_wgt_value,
          rslt_vol: rslt_vol_value,
          rem_qty: (ord_qty - rslt_qty_value).round(3),
          rem_wgt: (ord_wgt - rslt_wgt_value).round(3),
          rem_vol: (ord_vol - rslt_vol_value).round(3)
        }
      ]
    end

    def numeric_value(value)
      value.to_d.round(3).to_f
    end

    def customer_name_for(cust_cd)
      if !defined?(StdBzacMst) || !StdBzacMst.table_exists?
        return cust_cd
      end

      StdBzacMst.find_by(bzac_cd: cust_cd)&.bzac_nm.to_s.presence || cust_cd
    rescue ActiveRecord::StatementInvalid
      cust_cd
    end
end
