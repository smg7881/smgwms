class Std::Approval::PageComponent < Std::BasePageComponent
  private
    def collection_path(**) = helpers.std_approvals_path(**)
    def member_path(_id, **) = helpers.std_approvals_path(**)

    def batch_save_url
      helpers.batch_save_std_approvals_path
    end

    def search_fields
      [
        { field: "corp_nm", type: "popup", label: "법인", popup_type: "corp", code_field: "corp_cd", placeholder: "법인 선택" },
        { field: "menu_nm", type: "popup", label: "메뉴", popup_type: "menu", code_field: "menu_cd", placeholder: "메뉴 선택" },
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
        { field: "corp_cd", headerName: "법인코드", minWidth: 105, editable: true },
        { field: "corp_nm", headerName: "법인명", minWidth: 130, editable: true },
        { field: "menu_cd", headerName: "메뉴코드", minWidth: 110, editable: true },
        { field: "menu_nm", headerName: "메뉴명", minWidth: 150, editable: true },
        { field: "table_cd", headerName: "테이블", minWidth: 110, editable: true },
        { field: "col1_cd", headerName: "컬럼1", minWidth: 95, editable: true },
        { field: "col2_cd", headerName: "컬럼2", minWidth: 95, editable: true },
        { field: "col3_cd", headerName: "컬럼3", minWidth: 95, editable: true },
        { field: "col4_cd", headerName: "컬럼4", minWidth: 95, editable: true },
        { field: "col5_cd", headerName: "컬럼5", minWidth: 95, editable: true },
        {
          field: "asmt_apver_yn",
          headerName: "지정결재자",
          maxWidth: 105,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("CMM_USE_YN") },
          cellRenderer: "codeUseYnCellRenderer"
        },
        { field: "chrg_apver", headerName: "담당결재자", minWidth: 110, editable: true },
        {
          field: "not_asmt_apver_resp",
          headerName: "미지정직책",
          minWidth: 120,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("STD_APV_POSITION") }
        },
        {
          field: "apv_type_cd",
          headerName: "결재유형",
          minWidth: 110,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("STD_APV_TYPE") }
        },
        {
          field: "apv_delegt_yn",
          headerName: "결재위임",
          maxWidth: 105,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("CMM_USE_YN") },
          cellRenderer: "codeUseYnCellRenderer"
        },
        { field: "apv_delegate", headerName: "결재위임자", minWidth: 110, editable: true },
        { field: "rmk", headerName: "비고", minWidth: 180, editable: true },
        {
          field: "use_yn",
          headerName: "사용여부",
          maxWidth: 95,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("CMM_USE_YN") },
          cellRenderer: "codeUseYnCellRenderer"
        }
      ]
    end
end
