module Om
  module WaitingOrder
    class PageComponent < Om::BasePageComponent
      def initialize(query_params:, search_form: nil)
        super(query_params: query_params)
        @search_form = search_form || OpenStruct.new
      end

      private
        attr_reader :search_form

        def collection_path(**) = helpers.om_waiting_orders_path(**)
        def member_path(id, **) = helpers.om_waiting_order_path(id, **)
        def distribute_path(**) = helpers.distribute_om_waiting_orders_path(**)

        def search_fields
          [
            {
              field: "cust_nm",
              type: "popup",
              label: "고객",
              popup_type: "client",
              code_field: "cust_cd",
              value: search_form.respond_to?(:cust_nm) ? search_form.cust_nm : nil,
              code_value: search_form.respond_to?(:cust_cd) ? search_form.cust_cd : nil,
              display_width: "250px"
            },
            {
              field: "date_type",
              type: "select",
              label: "일자기준",
              options: [ [ "오더생성일자", "create_time" ], [ "납기요청일자", "aptd_req_ymd" ] ],
              value: search_form.respond_to?(:date_type) ? search_form.date_type : "create_time"
            },
            {
              field: "start_date",
              type: "date_picker",
              label: "시작일자",
              value: search_form.respond_to?(:start_date) ? search_form.start_date : Time.current.beginning_of_month.strftime("%Y-%m-%d")
            },
            {
              field: "end_date",
              type: "date_picker",
              label: "종료일자",
              value: search_form.respond_to?(:end_date) ? search_form.end_date : Time.current.end_of_month.strftime("%Y-%m-%d")
            }
          ]
        end
    end
  end
end
