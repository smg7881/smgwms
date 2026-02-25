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

        def master_columns
          [
            { field: "sctn", headerName: "구분", width: 80, pinned: "left" },
            { field: "hist_seq", headerName: "순번", width: 70, pinned: "left", cellClass: "text-right" },
            { field: "ord_no", headerName: "오더번호", width: 130 },
            { field: "cust_ord_no", headerName: "고객오더번호", width: 130 },
            { field: "ord_type_cd", headerName: "오더유형", width: 110 },
            { field: "cust_cd", headerName: "고객", width: 120 },
            { field: "ctrt_cust_cd", headerName: "계약고객", width: 120 },
            { field: "ord_req_cust_cd", headerName: "요청고객", width: 120 },
            { field: "bilg_cust_cd", headerName: "청구고객", width: 120 },
            { field: "ctrt_no", headerName: "계약번호", width: 120 },
            { field: "ord_stat_cd", headerName: "오더상태", width: 90 },
            { field: "ord_chrg_dept_cd", headerName: "오더담당부서", width: 120 },
            { field: "ord_ofcr", headerName: "담당자", width: 100 },
            { field: "retrngd_yn", headerName: "반품여부", width: 90 },
            { field: "back_ord_yn", headerName: "대기여부", width: 90 },
            { field: "cust_expr_yn", headerName: "고객긴급", width: 90, cellClassRules: { "text-red-500 font-bold": "x == 'Y'" } },
            { field: "cls_expr_yn", headerName: "마감긴급", width: 90, cellClassRules: { "text-red-500 font-bold": "x == 'Y'" } },
            { field: "prcl", headerName: "특이사항", width: 150 }
          ]
        end

        def detail_columns
          [
            { field: "sctn", headerName: "구분", width: 80 },
            { field: "seq", headerName: "순번", width: 70, cellClass: "text-right" },
            { field: "item_cd", headerName: "아이템코드", width: 120 },
            { field: "item_nm", headerName: "아이템명", width: 160 },
            { field: "basis_unit_clas_cd", headerName: "기본단위분류", width: 110 },
            {
              headerName: "오더내역",
              children: [
                { field: "ord_qty", headerName: "수량", width: 80, type: "numericColumn", cellClass: "bg-blue-50" },
                { field: "ord_wgt", headerName: "중량", width: 80, type: "numericColumn", cellClass: "bg-blue-50" },
                { field: "ord_vol", headerName: "부피", width: 80, type: "numericColumn", cellClass: "bg-blue-50" },
                { field: "unit_cd", headerName: "단위", width: 70 }
              ]
            }
          ]
        end
    end
  end
end
