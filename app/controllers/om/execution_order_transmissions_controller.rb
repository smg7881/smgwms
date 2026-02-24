module Om
  class ExecutionOrderTransmissionsController < ApplicationController
    def index
      @search_form = OpenStruct.new(params.fetch(:q, {}).permit(:ord_no).to_h)

      if request.format.json?
        # Mocking or querying the transmission logs table
        # Here we use a generic OmOrder table query for demonstration purposes.
        # Ideally, it should query a transmission history table.
        @orders = OmOrder.where(use_yn: "Y")

        if params[:q].present?
          if params[:q][:ord_no].present?
            @orders = @orders.where("ord_no LIKE ?", "%#{params[:q][:ord_no]}%")
          end
        end

        render json: {
          data: @orders.map do |order|
            {
              id: order.id,
              slc: false, # For checkbox selection
              exce_sctn: [ "출고", "입고", "운송", "창고배차지시" ].sample, # Mock Execution Section
              eo_no: "#{order.ord_no}-#{rand(1..5).to_s.rjust(3, '0')}", # Mock Execution Order No
              dpt_ar_nm: [ "전주센터", "물류창고A" ].sample,
              arv_ar_nm: [ "청주점", "대리점B" ].sample,
              work_pl_nm: [ "작업장1", "작업장2" ].sample,
              trms_seq: rand(1..10),
              trms_sctn_nm: [ "생성", "수정", "취소" ].sample,
              trms_hms: (order.create_time || Time.current).strftime("%Y-%m-%d %H:%M:%S"),
              rcv_hms: (order.create_time || Time.current + 2.minutes).strftime("%Y-%m-%d %H:%M:%S"),
              # trmsYn: E for Error, Y for success, N for ready
              trms_yn: [ "Y", "N", "E" ].sample,
              asign_idct_no: "ASIGN-#{rand(1000..9999)}",
              err_msg: [ "네트워크 오류", "유효하지 않은 데이터", nil ].sample
            }
          end
        }
      end
    end

    def retransmit
      target_ids = params[:ids]

      if target_ids.blank?
        return render json: { success: false, message: "재전송할 대상을 선택해주세요." }, status: :unprocessable_entity
      end

      # Mock update logic
      # Example: ExecutionOrderTransmissionLog.where(id: target_ids, trms_status_cd: 'E').update_all(trms_status_cd: 'N')
      updated_count = target_ids.length

      render json: {
        success: true,
        message: "#{updated_count}건의 데이터가 재전송 대기(N) 상태로 변경되었습니다."
      }
    rescue => e
      render json: { success: false, message: "처리 중 오류 발생: #{e.message}" }, status: :internal_server_error
    end
  end
end
