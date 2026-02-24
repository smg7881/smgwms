module Om
  module ServiceOrder
    class PageComponent < Om::BasePageComponent
      def initialize(query_params:, search_form: nil)
        super(query_params: query_params)
        @search_form = search_form || OpenStruct.new
      end

      private
        attr_reader :search_form

        def collection_path(**) = helpers.om_service_orders_path(**)
        def member_path(id, **) = helpers.om_service_order_path(id, **)
        def cancel_path(id, **) = helpers.cancel_om_service_order_path(id, **)

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
              field: "ord_no",
              type: "input",
              label: "오더번호",
              value: search_form.respond_to?(:ord_no) ? search_form.ord_no : nil
            }
          ]
        end
    end
  end
end
