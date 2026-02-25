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

        def master_columns
          [
            { field: "ord_stat_cd", headerName: "오더상태", width: 100, pinned: "left", cellClassRules: { 'text-blue-600 font-bold': "x == '출고대기'" } },
            { field: "ord_no", headerName: "오더번호", width: 150, pinned: "left" },
            { field: "creat_ymd", headerName: "생성일자", width: 110 },
            { field: "ord_type_cd", headerName: "오더유형", width: 120 },
            { field: "cust_bzac_nm", headerName: "고객거래처명", width: 150 },
            { field: "dpt_ar_nm", headerName: "출발지명", width: 130 },
            { field: "arv_ar_nm", headerName: "도착지명", width: 130 },
            { field: "ord_kind_cd", headerName: "조회 파라미터(디버그용1)", width: 180 },
            { field: "cmpt_sctn_cd", headerName: "조회 파라미터(디버그용2)", width: 180 }
          ]
        end

        def detail_columns
          [
            { field: "seq", headerName: "순번", width: 70, cellClass: "text-right" },
            { field: "item_cd", headerName: "아이템코드", width: 130 },
            { field: "item_nm", headerName: "아이템명", width: 180 },
            { field: "ord_qty", headerName: "오더수량", width: 100, type: "numericColumn", cellClass: "bg-blue-50 font-medium" },
            { field: "qty_unit_cd", headerName: "수량단위", width: 90 },
            { field: "ord_wgt", headerName: "오더중량", width: 100, type: "numericColumn" },
            { field: "wgt_unit_cd", headerName: "중량단위", width: 90 },
            { field: "ord_vol", headerName: "오더부피", width: 100, type: "numericColumn" },
            { field: "vol_unit_cd", headerName: "부피단위", width: 90 }
          ]
        end
    end
  end
end
