module Om
  module OrderWorkProgress
    class PageComponent < Om::BasePageComponent
      def initialize(query_params:, search_form: nil)
        super(query_params: query_params)
        @search_form = search_form || OpenStruct.new
      end

      private
        attr_reader :search_form

        def collection_path(**) = helpers.om_order_work_progresses_path(**)

        def search_fields
          [
            {
              field: "ord_no",
              type: "popup",
              label: "오더번호",
              popup_type: "order",
              code_field: "ord_no",
              value: search_form.respond_to?(:ord_no) ? search_form.ord_no : nil,
              placeholder: "오더번호 선택",
              required: true,
              display_width: "200px"
            }
          ]
        end

        def item_columns
          [
            { field: "div_dgr_cnt", headerName: "분배차수", width: 90 },
            { field: "item_cd", headerName: "아이템코드", width: 120 },
            { field: "item_nm", headerName: "아이템명", width: 160 },
            { field: "work_stat", headerName: "상태", width: 90 },
            { field: "basis_cd", headerName: "단위", width: 70 },
            {
              headerName: "오더",
              children: [
                { field: "ord_qty", headerName: "수량", width: 80, type: "numericColumn", cellClass: "text-right bg-blue-50" },
                { field: "ord_wgt", headerName: "중량", width: 80, type: "numericColumn", cellClass: "text-right bg-blue-50" },
                { field: "ord_vol", headerName: "부피", width: 80, type: "numericColumn", cellClass: "text-right bg-blue-50" }
              ]
            },
            {
              headerName: "실적",
              children: [
                { field: "rslt_qty", headerName: "수량", width: 80, type: "numericColumn", cellClass: "text-right bg-green-50" },
                { field: "rslt_wgt", headerName: "중량", width: 80, type: "numericColumn", cellClass: "text-right bg-green-50" },
                { field: "rslt_vol", headerName: "부피", width: 80, type: "numericColumn", cellClass: "text-right bg-green-50" }
              ]
            }
          ]
        end

        def progress_columns
          [
            { field: "car_no", headerName: "차량번호", width: 120 },
            { field: "dpt_ar_nm", headerName: "출발지", width: 130 },
            { field: "arv_ar_nm", headerName: "도착지", width: 130 },
            { field: "dpt_prar_date", headerName: "출발예정일시", width: 150 },
            { field: "dpt_date", headerName: "출발일시", width: 150, cellClass: "text-blue-600" },
            { field: "arv_prar_date", headerName: "도착예정일시", width: 150 },
            { field: "arv_date", headerName: "도착일시", width: 150, cellClass: "text-blue-600" },
            {
              headerName: "상태 Tracker",
              children: [
                { field: "gi", headerName: "출고", width: 80 },
                { field: "tran", headerName: "운송", width: 80 },
                { field: "gr", headerName: "입고", width: 80 },
                { field: "dpt", headerName: "출발", width: 80 },
                { field: "arv", headerName: "도착", width: 80 }
              ]
            }
          ]
        end
    end
  end
end
