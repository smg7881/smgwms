class Om::InternalOrdersController < Om::BaseController
  def index
    @selected_order = params[:selected_order].to_s.strip.upcase.presence

    respond_to do |format|
      format.html
      format.json do
        rows = internal_order_scope.to_a
        render json: rows.map { |row| master_row_json(row) }
      end
    end
  end

  def items
    order = find_order_by_id_param
    rows = order.items.order(:seq_no).map { |item| item_json(item) }
    render json: rows
  end

  def batch_save
    operations = batch_save_params
    result = { inserted: 0, updated: 0, deleted: 0 }
    errors = []

    ActiveRecord::Base.transaction do
      Array(operations[:rowsToInsert]).each do |attrs|
        if blank_order_row?(attrs)
          next
        end

        record = OmInternalOrder.new(order_params_from_row(attrs))
        record.ord_stat_cd = "WAIT" if record.ord_stat_cd.to_s.strip.blank?
        record.wait_ord_internal_yn = "N"
        record.cancel_yn = "N"

        assign_items_from_rows(record, attrs[:items], replace_existing: true)

        if record.save
          result[:inserted] += 1
        else
          errors.concat(record.errors.full_messages)
        end
      end

      Array(operations[:rowsToUpdate]).each do |attrs|
        ord_no = normalize_ord_no(attrs[:ord_no])
        if ord_no.blank?
          errors << "수정 대상 오더번호가 없습니다."
          next
        end

        record = OmInternalOrder.includes(:items).find_by(ord_no: ord_no)
        if record.nil?
          errors << "내부오더를 찾을 수 없습니다: #{ord_no}"
          next
        end

        if record.cancel_yn == "Y"
          errors << "취소된 오더는 수정할 수 없습니다: #{ord_no}"
          next
        end

        update_attrs = order_params_from_row(attrs)
        update_attrs.delete(:ord_no)
        update_attrs.delete(:wait_ord_internal_yn)
        update_attrs.delete(:cancel_yn)

        record.assign_attributes(update_attrs)
        assign_items_from_rows(record, attrs[:items], replace_existing: true)

        if record.save
          result[:updated] += 1
        else
          errors.concat(record.errors.full_messages)
        end
      end

      Array(operations[:rowsToDelete]).each do |entry|
        ord_no = extract_ord_no(entry)
        if ord_no.blank?
          next
        end

        record = OmInternalOrder.find_by(ord_no: ord_no)
        if record.nil?
          next
        end

        if record.cancel_yn == "Y"
          next
        end

        begin
          record.cancel!
          result[:deleted] += 1
        rescue ActiveRecord::RecordInvalid => e
          errors.concat(e.record.errors.full_messages)
        end
      end

      if errors.any?
        raise ActiveRecord::Rollback
      end
    end

    if errors.any?
      render json: { success: false, errors: errors.uniq }, status: :unprocessable_entity
    else
      render json: { success: true, message: "내부오더 데이터가 저장되었습니다.", data: result }
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
      params.fetch(:q, {}).permit(:ord_no, :ctrt_no, :ord_type_cd, :ord_stat_cd)
    end

    def order_params
      params.require(:order).permit(
        :ctrt_no,
        :ord_type_cd,
        :bilg_cust_cd,
        :ctrt_cust_cd,
        :ord_exec_dept_cd,
        :ord_exec_dept_nm,
        :ord_exec_ofcr_cd,
        :ord_exec_ofcr_nm,
        :ord_reason_cd,
        :remk,
        :dpt_type_cd,
        :dpt_cd,
        :dpt_zip_cd,
        :dpt_addr,
        :strt_req_ymd,
        :arv_type_cd,
        :arv_cd,
        :arv_zip_cd,
        :arv_addr,
        :aptd_req_dtm
      )
    end

    def items_params
      params.fetch(:items, []).map do |item|
        item.permit(*item_permitted_fields)
      end
    end

    def build_items(order)
      items_params.each do |item_attrs|
        if item_attrs[:item_cd].to_s.strip.present?
          order.items.build(item_attrs.to_h)
        end
      end
    end

    def batch_save_params
      params.permit(
        rowsToDelete: [],
        rowsToInsert: [
          *order_permitted_fields,
          { items: item_permitted_fields }
        ],
        rowsToUpdate: [
          *order_permitted_fields,
          { items: item_permitted_fields }
        ]
      )
    end

    def order_permitted_fields
      [
        :ord_no,
        :ord_stat_cd,
        :ctrt_no,
        :ord_type_cd,
        :bilg_cust_cd,
        :ctrt_cust_cd,
        :ord_exec_dept_cd,
        :ord_exec_dept_nm,
        :ord_exec_ofcr_cd,
        :ord_exec_ofcr_nm,
        :ord_reason_cd,
        :remk,
        :dpt_type_cd,
        :dpt_cd,
        :dpt_zip_cd,
        :dpt_addr,
        :strt_req_ymd,
        :arv_type_cd,
        :arv_cd,
        :arv_zip_cd,
        :arv_addr,
        :aptd_req_dtm,
        :wait_ord_internal_yn,
        :cancel_yn
      ]
    end

    def item_permitted_fields
      [
        :seq_no,
        :item_cd,
        :item_nm,
        :basis_unit_cd,
        :ord_qty,
        :qty_unit_cd,
        :ord_wgt,
        :wgt_unit_cd,
        :ord_vol,
        :vol_unit_cd
      ]
    end

    def order_params_from_row(row)
      row.permit(*order_permitted_fields).to_h.symbolize_keys
    end

    def item_params_from_row(row)
      row.permit(*item_permitted_fields).to_h.symbolize_keys
    end

    def assign_items_from_rows(order, item_rows, replace_existing:)
      if replace_existing && order.persisted?
        order.items.destroy_all
      end

      normalized = normalize_item_rows(item_rows)
      normalized.each do |attrs|
        order.items.build(attrs)
      end
    end

    def normalize_item_rows(item_rows)
      rows = []
      next_seq = 1

      Array(item_rows).each do |entry|
        attrs = item_params_from_row(entry)
        if attrs[:item_cd].to_s.strip.blank?
          next
        end

        seq_no = attrs[:seq_no].to_i
        if seq_no <= 0
          seq_no = next_seq
        end

        attrs[:seq_no] = seq_no
        rows << attrs
        next_seq = seq_no + 1
      end

      rows.first(20)
    end

    def blank_order_row?(attrs)
      keys = %i[ctrt_no ord_type_cd bilg_cust_cd ctrt_cust_cd dpt_cd arv_cd]
      keys.all? { |key| attrs[key].to_s.strip.blank? }
    end

    def extract_ord_no(entry)
      if entry.respond_to?(:to_h)
        hash = entry.to_h
        value = hash["ord_no"].presence || hash[:ord_no].presence
      else
        value = entry
      end

      normalize_ord_no(value)
    end

    def normalize_ord_no(value)
      value.to_s.strip.upcase.presence
    end

    def find_order_by_id_param
      raw = params[:id].to_s.strip
      order = OmInternalOrder.includes(:items).find_by(ord_no: raw)
      if order.nil? && raw.match?(/\A\d+\z/)
        order = OmInternalOrder.includes(:items).find_by(id: raw)
      end

      if order.nil?
        raise ActiveRecord::RecordNotFound
      end

      order
    end

    def internal_order_scope
      scope = OmInternalOrder.where(wait_ord_internal_yn: "N", cancel_yn: "N")
        .order(update_time: :desc, create_time: :desc, id: :desc)

      if search_ord_no.present?
        scope = scope.where("ord_no LIKE ?", "%#{search_ord_no}%")
      end
      if search_ctrt_no.present?
        scope = scope.where("ctrt_no LIKE ?", "%#{search_ctrt_no}%")
      end
      if search_ord_type_cd.present?
        scope = scope.where(ord_type_cd: search_ord_type_cd)
      end
      if search_ord_stat_cd.present?
        scope = scope.where(ord_stat_cd: search_ord_stat_cd)
      end

      scope
    end

    def search_ord_no
      search_params[:ord_no].to_s.strip.upcase.presence
    end

    def search_ctrt_no
      search_params[:ctrt_no].to_s.strip.upcase.presence
    end

    def search_ord_type_cd
      search_params[:ord_type_cd].to_s.strip.upcase.presence
    end

    def search_ord_stat_cd
      search_params[:ord_stat_cd].to_s.strip.upcase.presence
    end

    def master_row_json(order)
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
        update_time: order.update_time
      }
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

