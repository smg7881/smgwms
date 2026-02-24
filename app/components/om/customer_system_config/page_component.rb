class Om::CustomerSystemConfig::PageComponent < Om::BasePageComponent
  def initialize(query_params:, search_form:)
    super(query_params: query_params)
    @search_form = search_form
  end

  private
    attr_reader :search_form

    def collection_path(**) = helpers.om_customer_system_configs_path(**)
    def member_path(_id, **) = helpers.om_customer_system_configs_path(**)

    def batch_save_url
      helpers.batch_save_om_customer_system_configs_path
    end

    def search_fields
      [
        {
          field: "setup_unit_cd",
          type: "select",
          label: "설정단위",
          options: common_code_options("OM_SETUP_UNIT", include_all: true, all_label: "전체"),
          include_blank: false,
          required: true
        },
        {
          field: "cust_nm",
          type: "popup",
          label: "고객명",
          popup_type: "client",
          code_field: "cust_cd",
          value: search_form.cust_nm,
          placeholder: "고객 선택",
          display_width: "220px",
          code_width: "120px"
        },
        {
          field: "lclas_cd",
          type: "select",
          label: "대분류",
          options: common_code_options("OM_SETUP_LCLAS", include_all: true, all_label: "전체"),
          include_blank: false
        },
        {
          field: "setup_sctn_cd",
          type: "select",
          label: "설정구분",
          options: common_code_options("OM_SETUP_SCTN", include_all: true, all_label: "전체"),
          include_blank: false
        },
        {
          field: "module_nm",
          type: "input",
          label: "모듈명/항목명",
          placeholder: "모듈명 또는 항목명 검색"
        },
        {
          field: "use_yn",
          type: "select",
          label: "사용여부",
          options: common_code_options("CMM_USE_YN", include_all: true, all_label: "전체"),
          include_blank: false
        }
      ]
    end

    def columns
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
        { field: "id", headerName: "ID", hide: true, editable: false, sortable: false, filter: false },
        {
          field: "setup_unit_cd",
          headerName: "설정단위",
          minWidth: 110,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("OM_SETUP_UNIT") }
        },
        {
          field: "cust_cd",
          headerName: "고객코드",
          minWidth: 120,
          editable: true,
          lookup_popup_type: "client",
          lookup_code_field: "cust_cd",
          lookup_name_field: "cust_nm",
          lookup_popup_title: "고객 조회"
        },
        { field: "cust_nm", headerName: "고객명", minWidth: 160, editable: false },
        {
          field: "lclas_cd",
          headerName: "대분류",
          minWidth: 130,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("OM_SETUP_LCLAS") }
        },
        {
          field: "mclas_cd",
          headerName: "중분류",
          minWidth: 130,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("OM_SETUP_MCLAS") }
        },
        {
          field: "sclas_cd",
          headerName: "소분류",
          minWidth: 130,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("OM_SETUP_SCLAS") }
        },
        {
          field: "setup_sctn_cd",
          headerName: "설정구분",
          minWidth: 120,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("OM_SETUP_SCTN") }
        },
        { field: "module_nm", headerName: "모듈명", minWidth: 190, editable: true },
        { field: "setup_value", headerName: "설정값", minWidth: 120, editable: true },
        {
          field: "use_yn",
          headerName: "사용여부",
          maxWidth: 95,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("CMM_USE_YN") },
          cellRenderer: "codeUseYnCellRenderer"
        },
        { field: "update_by", headerName: "수정자", minWidth: 100, editable: false },
        { field: "update_time", headerName: "수정일시", minWidth: 160, formatter: "datetime", editable: false }
      ]
    end
end
