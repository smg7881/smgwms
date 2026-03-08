module Om
  module ServiceOrder
    class PageComponent < Om::BasePageComponent
      def initialize(query_params:, search_form:, selected_order:)
        super(query_params: query_params)
        @search_form = search_form || OpenStruct.new
        @selected_order = selected_order.to_s.strip.upcase.presence
      end

      private
        attr_reader :search_form, :selected_order

        def collection_path(**) = helpers.om_service_orders_path(**)
        def member_path(id, **) = helpers.om_service_order_path(id, **)
        def cancel_path(id, **) = helpers.cancel_om_service_order_path(id, **)
        def detail_collection_path(id, **) = helpers.items_om_service_order_path(id, **)

        def detail_grid_url
          if selected_order.present?
            detail_collection_path(selected_order, format: :json)
          else
            nil
          end
        end

        def detail_batch_save_url_template
          "/om/service_orders/:id/batch_save_items"
        end

        def detail_list_url_template
          "/om/service_orders/:id/items.json"
        end

        def selected_order_label
          if selected_order.present?
            "선택 오더: #{selected_order}"
          else
            "오더를 먼저 선택하세요."
          end
        end

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
            },
            {
              field: "ord_stat_cd",
              type: "select",
              label: "오더상태",
              options: common_code_options("OM_ORD_STAT", include_all: true),
              include_blank: false,
              value: search_form.respond_to?(:ord_stat_cd) ? search_form.ord_stat_cd : nil
            }
          ]
        end

        def master_columns
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
            { field: "ord_no", headerName: "오더번호", minWidth: 160, editable: false },
            {
              field: "ord_stat_cd",
              headerName: "오더상태",
              minWidth: 120,
              editable: false,
              formatter: "codeLabel",
              context: { codeMap: common_code_map("OM_ORD_STAT") }
            },
            {
              field: "ord_type_cd",
              headerName: "오더유형",
              minWidth: 120,
              editable: false,
              formatter: "codeLabel",
              context: { codeMap: common_code_map("75") }
            },
            { field: "cust_cd", headerName: "고객코드", minWidth: 120, editable: false },
            { field: "cust_nm", headerName: "고객명", minWidth: 170, editable: false },
            { field: "dpt_ar_cd", headerName: "출발지", minWidth: 120, editable: false },
            { field: "arv_ar_cd", headerName: "도착지", minWidth: 120, editable: false },
            { field: "item_cd", headerName: "대표아이템코드", minWidth: 140, editable: false },
            { field: "item_nm", headerName: "대표아이템명", minWidth: 180, editable: false },
            { field: "ord_qty", headerName: "수량", minWidth: 100, editable: false, type: "numericColumn" },
            { field: "ord_wgt", headerName: "중량", minWidth: 100, editable: false, type: "numericColumn" },
            { field: "ord_vol", headerName: "부피", minWidth: 100, editable: false, type: "numericColumn" },
            { field: "update_by", headerName: "수정자", minWidth: 95, editable: false },
            { field: "update_time", headerName: "수정일시", minWidth: 160, editable: false, formatter: "datetime" }
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
            {
              field: "seq_no",
              headerName: "순번",
              maxWidth: 90,
              editable: true,
              cellEditor: "agNumberCellEditor",
              type: "numericColumn"
            },
            { field: "ord_no", headerName: "오더번호", minWidth: 160, editable: false },
            { field: "item_cd", headerName: "아이템코드", minWidth: 150, editable: true },
            { field: "item_nm", headerName: "아이템명", minWidth: 190, editable: true },
            {
              field: "ord_qty",
              headerName: "수량",
              minWidth: 100,
              editable: true,
              cellEditor: "agNumberCellEditor",
              type: "numericColumn"
            },
            { field: "ord_wgt", headerName: "중량", minWidth: 100, editable: false, type: "numericColumn" },
            { field: "ord_vol", headerName: "부피", minWidth: 100, editable: false, type: "numericColumn" }
          ]
        end
    end
  end
end
