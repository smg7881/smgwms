module Om
  module WaitingOrder
    class PageComponent < Om::BasePageComponent
      DATE_TYPE_FALLBACK_OPTIONS = [
        { label: "오더생성일자", value: "CREATE_TIME" },
        { label: "납기요청일자", value: "APTD_REQ_YMD" }
      ].freeze

      def initialize(query_params:, search_form:)
        super(query_params: query_params)
        @search_form = search_form
      end

      private
        attr_reader :search_form

        def collection_path(**) = helpers.om_waiting_orders_path(**)
        def member_path(id, **) = helpers.om_waiting_order_path(id, **)

        def detail_list_url_template
          helpers.details_om_waiting_order_path("__ORD_NO__")
        end

        def detail_batch_save_url_template
          helpers.batch_save_om_waiting_order_path("__ORD_NO__")
        end

        def selected_order_label
          "오더를 먼저 선택하세요."
        end

        def search_fields
          [
            {
              field: "cust_nm",
              type: "popup",
              label: "고객",
              popup_type: "client",
              code_field: "cust_cd",
              value: search_form.cust_nm,
              placeholder: "고객 선택",
              display_width: "220px",
              code_width: "120px"
            },
            {
              field: "date_type",
              type: "select",
              label: "일자구분",
              options: date_type_options,
              include_blank: false,
              value: search_form.date_type
            },
            {
              field: "start_date",
              type: "date_picker",
              label: "시작일자",
              required: true,
              value: search_form.start_date
            },
            {
              field: "end_date",
              type: "date_picker",
              label: "종료일자",
              required: true,
              value: search_form.end_date
            }
          ]
        end

        def master_columns
          [
            { field: "ord_stat_nm", headerName: "오더상태", minWidth: 110, editable: false },
            { field: "ord_no", headerName: "오더번호", minWidth: 140, editable: false },
            { field: "ord_type_nm", headerName: "오더유형", minWidth: 120, editable: false },
            { field: "create_time", headerName: "오더생성일시", minWidth: 170, editable: false },
            { field: "aptd_req_ymd", headerName: "고객납기요청일자", minWidth: 140, editable: false },
            { field: "chg_aptd_ymd", headerName: "변경납기일시", minWidth: 140, editable: false },
            { field: "dpt_ar_nm", headerName: "출발지", minWidth: 140, editable: false },
            { field: "arv_ar_nm", headerName: "도착지", minWidth: 140, editable: false }
          ]
        end

        def detail_columns
          [
            {
              field: "__row_status",
              headerName: "상태",
              width: 68,
              minWidth: 68,
              maxWidth: 68,
              editable: false,
              sortable: false,
              filter: false,
              resizable: false,
              cellStyle: { textAlign: "center" },
              cellRenderer: "rowStatusCellRenderer"
            },
            { field: "ord_no", headerName: "오더번호", hide: true, editable: false },
            { field: "seq", headerName: "순번", width: 70, editable: false, cellClass: "text-right" },
            { field: "item_cd", headerName: "아이템코드", minWidth: 130, editable: false },
            { field: "item_nm", headerName: "아이템명", minWidth: 170, editable: false },
            {
              field: "basis_unit_clas_cd",
              headerName: "기본단위분류코드",
              minWidth: 130,
              editable: false,
              refData: common_code_map("20")
            },
            { field: "ord_qty", headerName: "오더수량", width: 95, editable: false, type: "numericColumn", cellClass: "text-right bg-sky-50" },
            { field: "ord_wgt", headerName: "오더중량", width: 95, editable: false, type: "numericColumn", cellClass: "text-right bg-sky-50" },
            { field: "ord_vol", headerName: "오더부피", width: 95, editable: false, type: "numericColumn", cellClass: "text-right bg-sky-50" },
            { field: "div_cmpt_qty", headerName: "분배완료수량", width: 105, editable: false, type: "numericColumn", cellClass: "text-right bg-green-50" },
            { field: "div_cmpt_wgt", headerName: "분배완료중량", width: 105, editable: false, type: "numericColumn", cellClass: "text-right bg-green-50" },
            { field: "div_cmpt_vol", headerName: "분배완료부피", width: 105, editable: false, type: "numericColumn", cellClass: "text-right bg-green-50" },
            { field: "avail_stock_qty", headerName: "가용재고수량", width: 105, editable: false, type: "numericColumn", cellClass: "text-right bg-violet-50" },
            { field: "avail_stock_wgt", headerName: "가용재고중량", width: 105, editable: false, type: "numericColumn", cellClass: "text-right bg-violet-50" },
            { field: "avail_stock_vol", headerName: "가용재고부피", width: 105, editable: false, type: "numericColumn", cellClass: "text-right bg-violet-50" },
            { field: "div_qty", headerName: "분배수량", width: 95, editable: true, type: "numericColumn", cellClass: "text-right bg-amber-50" },
            { field: "div_wgt", headerName: "분배중량", width: 95, editable: true, type: "numericColumn", cellClass: "text-right bg-amber-50" },
            { field: "div_vol", headerName: "분배부피", width: 95, editable: true, type: "numericColumn", cellClass: "text-right bg-amber-50" },
            { field: "balance_qty", headerName: "잔여수량", width: 95, editable: false, type: "numericColumn", cellClass: "text-right text-red-500" },
            { field: "balance_wgt", headerName: "잔여중량", width: 95, editable: false, type: "numericColumn", cellClass: "text-right text-red-500" },
            { field: "balance_vol", headerName: "잔여부피", width: 95, editable: false, type: "numericColumn", cellClass: "text-right text-red-500" }
          ]
        end

        def date_type_options
          options = common_code_options("91", include_all: false)
          has_real_options = options.any? { |option| option[:value].to_s.present? }

          if has_real_options
            options
          else
            DATE_TYPE_FALLBACK_OPTIONS
          end
        end
    end
  end
end
