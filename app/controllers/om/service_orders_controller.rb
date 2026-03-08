module Om
  class ServiceOrdersController < ApplicationController
    def index
      @search_form = OpenStruct.new(params.fetch(:q, {}).permit(:cust_cd, :cust_nm, :ord_no, :ord_stat_cd).to_h)
      @selected_order = params[:selected_order].to_s.strip.upcase.presence

      if request.format.json?
        rows = service_order_scope.to_a
        render json: rows.map { |order| master_row_json(order) }
      end
    end

    def items
      order = find_order_by_id_param
      render json: detail_rows_json(order)
    end

    def batch_save_items
      order = find_order_by_id_param
      operations = detail_batch_save_params

      rows_to_update = normalized_detail_rows(operations[:rowsToUpdate])
      rows_to_insert = normalized_detail_rows(operations[:rowsToInsert])
      rows_to_delete = Array(operations[:rowsToDelete])

      if rows_to_update.any?
        order.update!(rows_to_update.first)
        render json: { success: true, message: "오더 상세 내역이 저장되었습니다." }
        return
      end

      if rows_to_insert.any?
        order.update!(rows_to_insert.first)
        render json: { success: true, message: "오더 상세 내역이 저장되었습니다." }
        return
      end

      if rows_to_delete.any?
        order.update!(item_cd: nil, item_nm: nil, ord_qty: nil, ord_wgt: nil, ord_vol: nil)
        render json: { success: true, message: "오더 상세 내역이 삭제되었습니다." }
        return
      end

      render json: { success: true, message: "변경된 상세 내역이 없습니다." }
    rescue ActiveRecord::RecordInvalid => e
      render json: { success: false, message: e.record.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end

    def create
      @order = OmOrder.new(order_params)
      @order.ord_no = generate_ord_no
      @order.ord_stat_cd = "CREATED" if @order.ord_stat_cd.to_s.strip.blank?
      @order.use_yn = "Y"

      if @order.save
        render json: { success: true, message: "서비스 오더가 신규 등록되었습니다.", ord_no: @order.ord_no }
      else
        render json: { success: false, message: "저장에 실패했습니다: #{@order.errors.full_messages.join(', ')}" }, status: :unprocessable_entity
      end
    rescue StandardError => e
      render json: { success: false, message: "서버 오류: #{e.message}" }, status: :internal_server_error
    end

    def update
      @order = OmOrder.find_by!(ord_no: params[:id])

      if @order.update(order_params)
        render json: { success: true, message: "오더가 성공적으로 수정되었습니다." }
      else
        render json: { success: false, message: "수정에 실패했습니다: #{@order.errors.full_messages.join(', ')}" }, status: :unprocessable_entity
      end
    rescue ActiveRecord::RecordNotFound
      render json: { success: false, message: "오더를 찾을 수 없습니다." }, status: :not_found
    end

    def cancel
      @order = OmOrder.find_by!(ord_no: params[:id])

      cancel_reason = params.dig(:order, :cancel_reason)
      if cancel_reason.blank?
        render json: { success: false, message: "취소 사유를 입력해야 합니다." }, status: :unprocessable_entity
        return
      end

      if @order.update(ord_stat_cd: "CANCELED", manl_cmpt_rsn: cancel_reason.to_s.strip)
        render json: { success: true, message: "오더가 취소되었습니다." }
      else
        render json: { success: false, message: "오더 취소에 실패했습니다." }, status: :unprocessable_entity
      end
    rescue ActiveRecord::RecordNotFound
      render json: { success: false, message: "오더를 찾을 수 없습니다." }, status: :not_found
    end

    private
      def order_params
        params.require(:order).permit(
          :ord_type_cd,
          :ord_stat_cd,
          :cust_cd,
          :cust_nm,
          :billing_cust_cd,
          :contract_cust_cd,
          :dpt_ar_cd,
          :dpt_ar_nm,
          :arv_ar_cd,
          :arv_ar_nm,
          :aptd_req_ymd,
          :item_cd,
          :item_nm,
          :ord_qty,
          :ord_wgt,
          :ord_vol,
          :manl_cmpt_rsn,
          :work_stat_cd
        )
      end

      def detail_batch_save_params
        params.permit(
          rowsToDelete: [],
          rowsToInsert: detail_permitted_fields,
          rowsToUpdate: detail_permitted_fields
        )
      end

      def detail_permitted_fields
        [
          :seq_no,
          :ord_no,
          :item_cd,
          :item_nm,
          :ord_qty,
          :ord_wgt,
          :ord_vol
        ]
      end

      def normalized_detail_rows(rows)
        Array(rows).filter_map do |entry|
          attrs = if entry.respond_to?(:permit)
            entry.permit(*detail_permitted_fields).to_h
          else
            entry.to_h
          end

          item_cd = attrs["item_cd"].to_s.strip.upcase
          item_nm = attrs["item_nm"].to_s.strip

          if item_cd.blank? && item_nm.blank?
            nil
          else
            {
              item_cd: item_cd,
              item_nm: item_nm,
              ord_qty: number_or_nil(attrs["ord_qty"]),
              ord_wgt: number_or_nil(attrs["ord_wgt"]),
              ord_vol: number_or_nil(attrs["ord_vol"])
            }
          end
        end
      end

      def number_or_nil(value)
        raw = value.to_s.strip
        return nil if raw.blank?

        number = BigDecimal(raw)
        number
      rescue ArgumentError
        nil
      end

      def find_order_by_id_param
        raw = params[:id].to_s.strip
        order = OmOrder.find_by(ord_no: raw)

        if order.nil? && raw.match?(/\A\d+\z/)
          order = OmOrder.find_by(id: raw)
        end

        if order.nil?
          raise ActiveRecord::RecordNotFound
        end

        order
      end

      def detail_rows_json(order)
        has_detail = order.item_cd.to_s.strip.present? || order.item_nm.to_s.strip.present?
        return [] unless has_detail

        [
          {
            seq_no: 1,
            ord_no: order.ord_no,
            item_cd: order.item_cd,
            item_nm: order.item_nm,
            ord_qty: order.ord_qty,
            ord_wgt: order.ord_wgt,
            ord_vol: order.ord_vol
          }
        ]
      end

      def service_order_scope
        scope = OmOrder.where(use_yn: "Y", ord_type_cd: "10")
        scope = scope.order(update_time: :desc, create_time: :desc, ord_no: :desc)

        if @search_form.cust_cd.to_s.strip.present?
          scope = scope.where(cust_cd: @search_form.cust_cd.to_s.strip.upcase)
        end

        if @search_form.cust_nm.to_s.strip.present?
          scope = scope.where("cust_nm LIKE ?", "%#{@search_form.cust_nm.to_s.strip}%")
        end

        if @search_form.ord_no.to_s.strip.present?
          scope = scope.where("ord_no LIKE ?", "%#{@search_form.ord_no.to_s.strip.upcase}%")
        end

        if @search_form.ord_stat_cd.to_s.strip.present?
          scope = scope.where(ord_stat_cd: @search_form.ord_stat_cd.to_s.strip.upcase)
        end

        scope
      end

      def master_row_json(order)
        {
          id: order.id,
          ord_no: order.ord_no,
          ord_stat_cd: order.ord_stat_cd,
          ord_type_cd: order.ord_type_cd,
          cust_cd: order.cust_cd,
          cust_nm: order.cust_nm,
          dpt_ar_cd: order.dpt_ar_cd,
          dpt_ar_nm: order.dpt_ar_nm,
          arv_ar_cd: order.arv_ar_cd,
          arv_ar_nm: order.arv_ar_nm,
          item_cd: order.item_cd,
          item_nm: order.item_nm,
          ord_qty: order.ord_qty,
          ord_wgt: order.ord_wgt,
          ord_vol: order.ord_vol,
          update_by: order.update_by,
          update_time: order.update_time,
          create_by: order.create_by,
          create_time: order.create_time
        }
      end

      def generate_ord_no
        "SVC-#{Time.current.strftime('%Y%m%d%H%M%S')}-#{rand(100..999)}"
      end
  end
end
