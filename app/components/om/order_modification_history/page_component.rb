module Om
  module OrderModificationHistory
    class PageComponent < Om::BasePageComponent
      def initialize(query_params:, search_form: nil)
        super(query_params: query_params)
        @search_form = search_form || OpenStruct.new
      end

      private
        attr_reader :search_form

        def collection_path(**) = helpers.om_order_modification_histories_path(**)
        def member_path(id, **) = helpers.om_order_modification_history_path(id, **)

        def search_fields
          [
            {
              field: "ord_no",
              type: "popup",
              label: "오더번호",
              popup_type: "order",
              code_field: "ord_no",
              value: search_form.respond_to?(:ord_no) ? search_form.ord_no : nil,
              placeholder: "오더 선택",
              required: true,
              display_width: "200px"
            },
            {
              field: "hist_seq",
              type: "input",
              label: "이력순번",
              placeholder: "전체",
              inputmode: "numeric"
            }
          ]
        end
    end
  end
end
