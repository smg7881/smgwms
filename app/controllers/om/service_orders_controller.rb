module Om
  class ServiceOrdersController < ApplicationController
    def index
      @search_form = OpenStruct.new(params.fetch(:q, {}).permit(:cust_cd, :cust_nm, :ord_no).to_h)

      if request.format.json?
        # Handle AG Grid JSON request or search results
        @orders = OmOrder.where(use_yn: "Y", ord_type_cd: "10") # 10 for Service Order

        if params[:q].present?
          if params[:q][:cust_cd].present?
            @orders = @orders.where(cust_cd: params[:q][:cust_cd])
          end

          if params[:q][:ord_no].present?
            @orders = @orders.where("ord_no LIKE ?", "%#{params[:q][:ord_no]}%")
          end
        end

        render json: {
          data: @orders.map do |order|
            {
              id: order.id,
              ord_stat_cd: order.ord_stat_cd,
              ord_no: order.ord_no,
              ord_type_cd: order.ord_type_cd,
              ctrt_no: order.ctrt_no,
              cust_cd: order.cust_cd,
              req_start_dt: order.req_start_dt&.strftime("%Y-%m-%d"),
              aptd_req_ymd: order.aptd_req_ymd&.strftime("%Y-%m-%d %H:%M"),
              dpt_type_cd: order.dpt_type_cd,
              dpt_cd: order.dpt_cd,
              arv_type_cd: order.arv_type_cd,
              arv_cd: order.arv_cd,
              remark: order.remark
            }
          end
        }
      end
    end

    def create
      # 실제 구현에서는 Parameter Strong validation과 트랜잭션 처리가 필요합니다.
      # 여기서는 Mock 구현으로 오더 생성 로직을 흉내냅니다.
      @order = OmOrder.new(order_params)
      @order.ord_no = generate_ord_no
      @order.ord_stat_cd = "CREATED" # Default state
      @order.use_yn = "Y"

      if @order.save
        render json: { success: true, message: "서비스 오더가 신규 등록되었습니다.", ord_no: @order.ord_no }
      else
        render json: { success: false, message: "저장에 실패했습니다: #{@order.errors.full_messages.join(', ')}" }, status: :unprocessable_entity
      end
    rescue => e
      render json: { success: false, message: "서버 오류: #{e.message}" }, status: :internal_server_error
    end

    def update
      @order = OmOrder.find_by!(ord_no: params[:id])

      # 가용재고 체크 부족시 거부 로직 (Mock)
      # if !available_stock_enough?
      #   return render json: { success: false, message: "재고가 부족합니다." }, status: :unprocessable_entity
      # end

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
        return render json: { success: false, message: "취소 사유를 입력해야 합니다." }, status: :unprocessable_entity
      end

      if @order.update(ord_stat_cd: "CANCELED", cancel_reason: cancel_reason)
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
          :ctrt_no, :ord_type_cd, :cust_cd, :bilg_cust_cd, :req_cust_cd, :ctrt_cust_cd,
          :cust_ofcr_nm, :cust_ofcr_tel, :tran_div_cd, :remark,
          :dpt_type_cd, :dpt_cd, :dpt_addr, :req_start_dt,
          :arv_type_cd, :arv_cd, :arv_addr, :aptd_req_ymd,
          :change_reason
        )
      end

      def generate_ord_no
        "SVC-#{Time.current.strftime('%Y%m%d%H%M%S')}-#{rand(100..999)}"
      end
  end
end
