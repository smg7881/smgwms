class Wm::CustRule::PageComponent < Wm::BasePageComponent
  private
    def collection_path(**) = helpers.wm_cust_rules_path(**)
    def member_path(id, **) = helpers.wm_cust_rule_path(id, **)

    def batch_save_url
      helpers.batch_save_wm_cust_rules_path
    end

    def search_fields
      [
        {
          field: "workpl_cd",
          type: "popup",
          label: "작업장",
          popup_type: "workpl",
          code_field: "workpl_cd"
        },
        {
          field: "cust_cd",
          type: "popup",
          label: "고객",
          popup_type: "cust",
          code_field: "cust_cd"
        },
        {
          field: "inout_sctn",
          type: "select",
          label: "입출고구분",
          options: common_code_options("82", include_all: true),
          include_blank: false
        },
        {
          field: "inout_type",
          type: "select",
          label: "입출고유형",
          options: common_code_options("152", include_all: true) + common_code_options("154", include_all: true).reject { |o| o[:value] == "" },
          include_blank: false
        },
        {
          field: "rule_sctn",
          type: "select",
          label: "RULE 구분",
          options: common_code_options("106", include_all: true),
          include_blank: false
        },
        {
          field: "aply_yn",
          type: "select",
          label: "적용여부",
          options: common_code_options("06", include_all: true),
          include_blank: false
        }
      ]
    end

    def columns
      [
        {
          field: "__row_status",
          headerName: "상태",
          width: 68, minWidth: 68, maxWidth: 68,
          editable: false, sortable: false, filter: false, resizable: false,
          cellStyle: { textAlign: "center" },
          cellRenderer: "rowStatusCellRenderer"
        },
        {
          field: "workpl_cd",
          headerName: "작업장",
          minWidth: 130,
          editable: true,
          cellEditor: "agPopupCellEditor",
          cellEditorParams: { popup_type: "workpl" }
        },
        {
          field: "cust_cd",
          headerName: "고객코드",
          minWidth: 130,
          editable: true,
          cellEditor: "agPopupCellEditor",
          cellEditorParams: { popup_type: "cust" }
        },
        {
          field: "inout_sctn",
          headerName: "입출고구분",
          minWidth: 150,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("82") },
          cellRenderer: "codeRenderer",
          cellRendererParams: { code_grp: "82" }
        },
        {
          field: "inout_type",
          headerName: "입출고유형",
          minWidth: 150,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: (common_code_values("152") + common_code_values("154")).uniq },
          cellRenderer: "codeRenderer",
          cellRendererParams: { codes: (common_code_values("152") + common_code_values("154")).uniq }
        },
        {
          field: "rule_sctn",
          headerName: "RULE구분",
          minWidth: 150,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("106") },
          cellRenderer: "codeRenderer",
          cellRendererParams: { code_grp: "106" }
        },
        {
          field: "aply_yn",
          headerName: "적용여부",
          maxWidth: 110,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("06") },
          cellRenderer: "codeRenderer",
          cellRendererParams: { code_grp: "06" }
        },
        { field: "remark", headerName: "비고", minWidth: 220, editable: true },
        { field: "update_by", headerName: "수정자", minWidth: 100, editable: false },
        { field: "update_time", headerName: "수정일시", minWidth: 170, formatter: "datetime", editable: false },
        { field: "create_by", headerName: "생성자", minWidth: 100, editable: false },
        { field: "create_time", headerName: "생성일시", minWidth: 170, formatter: "datetime", editable: false }
      ]
    end
end
