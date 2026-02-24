module Om
  module OrderInquiry
    class PageComponent < Om::BasePageComponent
      def initialize(query_params:, search_form: nil)
        super(query_params: query_params)
        @search_form = search_form || OpenStruct.new
      end

      private
        attr_reader :search_form

        def collection_path(**) = helpers.om_order_inquiries_path(**)
        def member_path(id, **) = helpers.om_order_inquiry_path(id, **)

        def search_fields
          [
            {
              field: "cust_nm",
              type: "popup",
              label: "고객",
              popup_type: "customer",
              code_field: "cust_cd",
              value: search_form.respond_to?(:cust_nm) ? search_form.cust_nm : nil,
              placeholder: "고객명",
              required: true,
              display_width: "220px",
              code_width: "120px"
            },
            {
              field: "date_type",
              type: "select",
              label: "일자기준",
              options: [ [ "생성일자", "creat_ymd" ], [ "납기요청일", "aptd_req_ymd" ] ],
              include_blank: false,
              required: true
            },
            {
              field: "strt_ymd",
              type: "date_picker",
              label: "시작일자",
              required: true
            },
            {
              field: "end_ymd",
              type: "date_picker",
              label: "종료일자",
              required: true
            },
            {
              field: "ord_kind_cd",
              type: "select",
              label: "오더종류",
              options: [ [ "정상", "NORMAL" ], [ "반품", "RETURN" ] ],
              include_blank: true,
              blank_label: "전체 (정상/반품)"
            },
            {
              field: "cmpt_sctn_cd",
              type: "select",
              label: "완료구분",
              options: [ [ "자동완료", "AUTO" ], [ "수동완료", "MANUAL" ] ],
              include_blank: true,
              blank_label: "전체 (자동/수동)"
            },
            {
              field: "ord_sctn_cd",
              type: "select",
              label: "오더구분",
              options: [ [ "서비스오더", "10" ], [ "내부오더", "20" ] ],
              include_blank: true,
              blank_label: "전체 (서비스/내부)"
            }
          ]
        end
    end
  end
end
