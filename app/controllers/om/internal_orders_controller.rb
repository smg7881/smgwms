class Om::InternalOrdersController < Om::BaseController
  def index
    @search_form = Om::InternalOrderSearchForm.new(search_params.to_h)

    respond_to do |format|
      format.html
      format.json do
        ord_no = search_params[:ord_no].to_s.strip
        if ord_no.blank?
          render json: { success: false, message: "오더번호를 입력하세요." }, status: :unprocessable_entity
          return
        end

        order = OmInternalOrder.includes(:items).find_by(ord_no: ord_no)
        if order.nil?
          render json: { success: false, message: "오더를 찾을 수 없습니다." }, status: :not_found
          return
        end

        render json: { success: true, data: order_json(order) }
      end
    end
  end

  def create
    order = OmInternalOrder.new(order_params)
    order.ord_stat_cd = "WAIT"
    order.wait_ord_internal_yn = "N"
    order.cancel_yn = "N"

    build_items(order)

    if order.save
      render json: { success: true, message: "내부오더가 등록되었습니다.", data: order_json(order) }
    else
      render json: { success: false, errors: order.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    order = OmInternalOrder.find(params[:id])

    if order.cancel_yn == "Y"
      render json: { success: false, message: "취소된 오더는 수정할 수 없습니다." }, status: :unprocessable_entity
      return
    end

    ActiveRecord::Base.transaction do
      order.assign_attributes(order_params)
      order.items.destroy_all
      build_items(order)
      order.save!
    end

    render json: { success: true, message: "내부오더가 수정되었습니다.", data: order_json(order.reload) }
  rescue ActiveRecord::RecordInvalid => e
    render json: { success: false, errors: e.record.errors.full_messages }, status: :unprocessable_entity
  end

  def cancel
    order = OmInternalOrder.find(params[:id])

    if order.cancel_yn == "Y"
      render json: { success: false, message: "이미 취소된 오더입니다." }, status: :unprocessable_entity
      return
    end

    order.cancel!
    render json: { success: true, message: "오더가 취소되었습니다.", data: order_json(order) }
  rescue ActiveRecord::RecordInvalid => e
    render json: { success: false, errors: e.record.errors.full_messages }, status: :unprocessable_entity
  end

  private
    def menu_code_for_permission
      "OM_INTERNAL_ORD"
    end

    def search_params
      params.fetch(:q, {}).permit(:ord_no)
    end

    def order_params
      params.require(:order).permit(
        :ctrt_no, :ord_type_cd, :bilg_cust_cd, :ctrt_cust_cd,
        :ord_exec_dept_cd, :ord_exec_dept_nm, :ord_exec_ofcr_cd, :ord_exec_ofcr_nm,
        :ord_reason_cd, :remk,
        :dpt_type_cd, :dpt_cd, :dpt_zip_cd, :dpt_addr, :strt_req_ymd,
        :arv_type_cd, :arv_cd, :arv_zip_cd, :arv_addr, :aptd_req_dtm
      )
    end

    def items_params
      params.fetch(:items, []).map do |item|
        item.permit(
          :seq_no, :item_cd, :item_nm, :basis_unit_cd,
          :ord_qty, :qty_unit_cd, :ord_wgt, :wgt_unit_cd, :ord_vol, :vol_unit_cd
        )
      end
    end

    def build_items(order)
      items_params.each do |item_attrs|
        if item_attrs[:item_cd].to_s.strip.present?
          order.items.build(item_attrs.to_h)
        end
      end
    end

    def order_json(order)
      {
        id: order.id,
        ord_no: order.ord_no,
        ord_stat_cd: order.ord_stat_cd,
        ctrt_no: order.ctrt_no,
        ord_type_cd: order.ord_type_cd,
        bilg_cust_cd: order.bilg_cust_cd,
        ctrt_cust_cd: order.ctrt_cust_cd,
        ord_exec_dept_cd: order.ord_exec_dept_cd,
        ord_exec_dept_nm: order.ord_exec_dept_nm,
        ord_exec_ofcr_cd: order.ord_exec_ofcr_cd,
        ord_exec_ofcr_nm: order.ord_exec_ofcr_nm,
        ord_reason_cd: order.ord_reason_cd,
        remk: order.remk,
        dpt_type_cd: order.dpt_type_cd,
        dpt_cd: order.dpt_cd,
        dpt_zip_cd: order.dpt_zip_cd,
        dpt_addr: order.dpt_addr,
        strt_req_ymd: order.strt_req_ymd,
        arv_type_cd: order.arv_type_cd,
        arv_cd: order.arv_cd,
        arv_zip_cd: order.arv_zip_cd,
        arv_addr: order.arv_addr,
        aptd_req_dtm: order.aptd_req_dtm,
        wait_ord_internal_yn: order.wait_ord_internal_yn,
        cancel_yn: order.cancel_yn,
        create_by: order.create_by,
        create_time: order.create_time,
        update_by: order.update_by,
        update_time: order.update_time,
        items: order.items.order(:seq_no).map { |item| item_json(item) }
      }
    end

    def item_json(item)
      {
        id: item.id,
        seq_no: item.seq_no,
        item_cd: item.item_cd,
        item_nm: item.item_nm,
        basis_unit_cd: item.basis_unit_cd,
        ord_qty: item.ord_qty,
        qty_unit_cd: item.qty_unit_cd,
        ord_wgt: item.ord_wgt,
        wgt_unit_cd: item.wgt_unit_cd,
        ord_vol: item.ord_vol,
        vol_unit_cd: item.vol_unit_cd
      }
    end
end
