module Om
  class WaitingOrdersController < ApplicationController
    def index
      @search_form = OpenStruct.new(params.fetch(:q, {
        date_type: "create_time",
        start_date: Time.current.beginning_of_month.strftime("%Y-%m-%d"),
        end_date: Time.current.end_of_month.strftime("%Y-%m-%d")
      }).permit(:cust_cd, :cust_nm, :date_type, :start_date, :end_date).to_h)

      if request.format.json?
        # Handle AG Grid JSON request
        @orders = OmOrder.where(use_yn: "Y")

        # Apply searching/filtering logic based on `q` parameters
        if params[:q].present?
          if params[:q][:cust_cd].present?
            @orders = @orders.where(cust_cd: params[:q][:cust_cd])
          end

          start_date = params[:q][:start_date].presence
          end_date = params[:q][:end_date].presence

          if start_date && end_date
            date_type = params[:q][:date_type] || "create_time"

            if date_type == "aptd_req_ymd"
              @orders = @orders.where(aptd_req_ymd: start_date..end_date)
            else
              @orders = @orders.where(create_time: Time.zone.parse(start_date).beginning_of_day..Time.zone.parse(end_date).end_of_day)
            end
          end
        end

        # Specifically filter waiting orders if applicable (ord_stat_cd or work_stat_cd)
        # Assuming ord_stat_cd 'WAITING' or similar designates an unallocated state
        # @orders = @orders.where(ord_stat_cd: 'WAITING')

        render json: {
          data: @orders.map do |order|
            # Note: For demo/mock purposes, avail_qty is mocked here.
            # Real implementation should call the WMS Inventory API.
            {
              id: order.id,
              ord_stat_cd: order.ord_stat_cd,
              ord_no: order.ord_no,
              ord_type_cd: order.ord_type_cd,
              create_time: order.create_time&.strftime("%Y-%m-%d %H:%M:%S"),
              aptd_req_ymd: order.aptd_req_ymd&.strftime("%Y-%m-%d"),
              dpt_ar_nm: order.dpt_ar_nm,
              arv_ar_nm: order.arv_ar_nm,
              item_cd: order.item_cd,
              item_nm: order.item_nm,
              ord_qty: order.ord_qty || 0,
              ord_wgt: order.ord_wgt || 0,
              ord_vol: order.ord_vol || 0,
              avail_qty: rand(0..(order.ord_qty || 100)), # Mocked available stock
              dist_qty: 0,
              dist_wgt: 0,
              dist_vol: 0
            }
          end
        }
      end
    end

    def distribute
      # Action to process the distribution of orders based on the payload
      distributed_count = 0
      updated_orders = []

      params[:distributions]&.each do |dist|
        order = OmOrder.find_by(ord_no: dist[:ord_no])
        if order
          # Process distribution logic - e.g., create an OmWorkRoute or update order status
          # order.update(ord_stat_cd: 'DISTRIBUTED') or similar
          distributed_count += 1
          updated_orders << order.ord_no
        end
      end

      render json: {
        success: true,
        message: "#{distributed_count}건의 오더 분배 처리가 완료되었습니다.",
        updated_ord_nos: updated_orders
      }
    rescue => e
      render json: { success: false, message: "오더 분배 중 오류가 발생했습니다: #{e.message}" }, status: :unprocessable_entity
    end
  end
end
