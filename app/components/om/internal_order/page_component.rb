class Om::InternalOrder::PageComponent < Om::BasePageComponent
  def initialize(query_params:, selected_order:)
    super(query_params: query_params)
    @selected_order = selected_order.presence
  end

  private
    attr_reader :selected_order

    def collection_path(**) = helpers.om_internal_orders_path(**)
    def member_path(id, **) = helpers.om_internal_order_path(id, **)

    def master_batch_save_url
      helpers.batch_save_om_internal_orders_path
    end

    def item_list_url_template
      "/om/internal_orders/:id/items.json"
    end

    def selected_order_label
      if selected_order.present?
        "선택 내부오더: #{selected_order}"
      else
        "내부오더를 먼저 선택하세요."
      end
    end

    def search_fields
      [
        { field: "ord_no", type: "input", label: "오더번호", placeholder: "오더번호 검색" },
        { field: "ctrt_no", type: "input", label: "계약번호", placeholder: "계약번호 검색" },
        {
          field: "ord_type_cd",
          type: "select",
          label: "오더유형",
          options: common_code_options("75", include_all: true),
          include_blank: false
        },
        {
          field: "ord_stat_cd",
          type: "select",
          label: "오더상태",
          options: common_code_options("OM_ORD_STAT", include_all: true),
          include_blank: false
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
        { field: "ord_no", headerName: "오더번호", minWidth: 170, editable: false },
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
        { field: "ctrt_no", headerName: "계약번호", minWidth: 140, editable: false },
        { field: "bilg_cust_cd", headerName: "청구고객", minWidth: 120, editable: false },
        { field: "ctrt_cust_cd", headerName: "계약고객", minWidth: 120, editable: false },
        { field: "dpt_cd", headerName: "출발지코드", minWidth: 120, editable: false },
        { field: "arv_cd", headerName: "도착지코드", minWidth: 120, editable: false },
        { field: "strt_req_ymd", headerName: "시작요청일", minWidth: 120, editable: false },
        { field: "aptd_req_dtm", headerName: "납기요청일시", minWidth: 160, editable: false },
        { field: "update_by", headerName: "수정자", minWidth: 95, editable: false },
        { field: "update_time", headerName: "수정일시", minWidth: 160, formatter: "datetime", editable: false }
      ]
    end

    def item_columns
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
        { field: "seq_no", headerName: "순번", maxWidth: 90, editable: true, cellEditor: "agNumberCellEditor" },
        { field: "item_cd", headerName: "아이템코드", minWidth: 140, editable: true },
        { field: "item_nm", headerName: "아이템명", minWidth: 180, editable: true },
        { field: "basis_unit_cd", headerName: "기본단위", minWidth: 100, editable: true },
        { field: "ord_qty", headerName: "수량", minWidth: 100, editable: true, cellEditor: "agNumberCellEditor", type: "numericColumn" },
        {
          field: "qty_unit_cd",
          headerName: "수량단위",
          minWidth: 100,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: qty_unit_options }
        },
        { field: "ord_wgt", headerName: "중량", minWidth: 100, editable: true, cellEditor: "agNumberCellEditor", type: "numericColumn" },
        {
          field: "wgt_unit_cd",
          headerName: "중량단위",
          minWidth: 100,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: wgt_unit_options }
        },
        { field: "ord_vol", headerName: "부피", minWidth: 100, editable: true, cellEditor: "agNumberCellEditor", type: "numericColumn" },
        {
          field: "vol_unit_cd",
          headerName: "부피단위",
          minWidth: 100,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: vol_unit_options }
        }
      ]
    end

    def detail_form_model
      @detail_form_model ||= OmInternalOrder.new
    end

    def detail_form_data
      {
        action: "submit->resource-form#submit submit->om-internal-order#preventDetailSubmit"
      }
    end

    def header_form_fields
      [
        { field: "ord_no", type: "input", label: "오더번호", readonly: true, target: "detailField" },
        { field: "ord_stat_cd", type: "input", label: "오더상태", readonly: true, target: "detailField" },
        { field: "create_time", type: "input", label: "생성일시", readonly: true, target: "detailField" },
        { field: "ctrt_no", type: "input", label: "계약번호", target: "detailField" },
        {
          field: "ord_type_cd",
          type: "select",
          label: "오더유형",
          required: true,
          options: common_code_options("75"),
          include_blank: "선택",
          target: "detailField"
        },
        { field: "bilg_cust_cd", type: "input", label: "청구고객", required: true, target: "detailField" },
        { field: "ctrt_cust_cd", type: "input", label: "계약고객", required: true, target: "detailField" },
        {
          field: "ord_reason_cd",
          type: "select",
          label: "사유코드",
          options: common_code_options("87", include_all: true),
          include_blank: false,
          target: "detailField"
        },
        { field: "ord_exec_dept_cd", type: "input", label: "집행부서", target: "detailField" },
        { field: "ord_exec_dept_nm", type: "input", label: "집행부서명", target: "detailField" },
        { field: "ord_exec_ofcr_cd", type: "input", label: "집행담당자", target: "detailField" },
        { field: "ord_exec_ofcr_nm", type: "input", label: "집행담당자명", target: "detailField" },
        { field: "remk", type: "input", label: "특이사항", colspan: 2, target: "detailField" }
      ]
    end

    def location_form_fields
      [
        {
          field: "dpt_type_cd",
          type: "select",
          label: "출발지유형",
          required: true,
          options: loc_type_options,
          include_blank: "선택",
          target: "detailField"
        },
        { field: "dpt_cd", type: "input", label: "출발지코드", required: true, target: "detailField" },
        { field: "dpt_zip_cd", type: "input", label: "출발지우편번호", target: "detailField" },
        { field: "dpt_addr", type: "input", label: "출발지주소", target: "detailField" },
        { field: "strt_req_ymd", type: "input", input_type: "date", label: "시작요청일", target: "detailField" },
        {
          field: "arv_type_cd",
          type: "select",
          label: "도착지유형",
          required: true,
          options: loc_type_options,
          include_blank: "선택",
          target: "detailField"
        },
        { field: "arv_cd", type: "input", label: "도착지코드", required: true, target: "detailField" },
        { field: "arv_zip_cd", type: "input", label: "도착지우편번호", target: "detailField" },
        { field: "arv_addr", type: "input", label: "도착지주소", target: "detailField" },
        { field: "aptd_req_dtm", type: "input", input_type: "datetime-local", label: "납기요청일시", target: "detailField" }
      ]
    end

    def loc_type_options
      common_code_options("OM_LOC_TYPE")
    end

    def qty_unit_options
      common_code_values("OM_QTY_UNIT")
    end

    def wgt_unit_options
      common_code_values("OM_WGT_UNIT")
    end

    def vol_unit_options
      common_code_values("OM_VOL_UNIT")
    end
end

