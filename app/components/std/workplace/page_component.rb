class Std::Workplace::PageComponent < Std::BasePageComponent
  private
    def collection_path(**) = helpers.std_workplaces_path(**)
    def member_path(_id, **) = helpers.std_workplaces_path(**)

    def batch_save_url
      helpers.batch_save_std_workplaces_path
    end

    def search_fields
      [
        { field: "corp_nm", type: "popup", label: "법인", popup_type: "corp", code_field: "corp_cd", placeholder: "법인 선택" },
        { field: "workpl_nm_cd", type: "popup", label: "작업장", popup_type: "workplace", code_field: "workpl_cd", placeholder: "작업장 선택" },
        {
          field: "workpl_sctn_cd",
          type: "select",
          label: "작업장구분",
          options: common_code_options("STD_WORKPL_SCTN", include_all: true, all_label: "전체"),
          include_blank: false
        },
        {
          field: "use_yn_cd",
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
        { field: "corp_cd", headerName: "법인코드", minWidth: 110, editable: true },
        { field: "workpl_cd", headerName: "작업장코드", minWidth: 120, editable: true },
        { field: "upper_workpl_cd", headerName: "상위작업장", minWidth: 120, editable: true },
        { field: "dept_cd", headerName: "부서코드", minWidth: 110, editable: true },
        { field: "workpl_nm", headerName: "작업장명", minWidth: 160, editable: true },
        {
          field: "workpl_sctn_cd",
          headerName: "작업장구분",
          minWidth: 120,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("STD_WORKPL_SCTN") }
        },
        {
          field: "capa_spec_unit_cd",
          headerName: "용량단위",
          minWidth: 100,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("STD_CAPA_UNIT") }
        },
        { field: "max_capa", headerName: "최대용량", minWidth: 110, editable: true, cellEditor: "agNumberCellEditor" },
        { field: "adpt_capa", headerName: "적정용량", minWidth: 110, editable: true, cellEditor: "agNumberCellEditor" },
        {
          field: "dimem_spec_unit_cd",
          headerName: "면적단위",
          minWidth: 100,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("STD_DIMEM_UNIT") }
        },
        { field: "dimem", headerName: "면적", minWidth: 90, editable: true, cellEditor: "agNumberCellEditor" },
        {
          field: "wm_yn_cd",
          headerName: "창고관리",
          maxWidth: 100,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("CMM_USE_YN") },
          cellRenderer: "codeUseYnCellRenderer"
        },
        { field: "bzac_cd", headerName: "거래처", minWidth: 100, editable: true },
        { field: "ctry_cd", headerName: "국가", maxWidth: 90, editable: true },
        { field: "zip_cd", headerName: "우편번호", minWidth: 100, editable: true },
        { field: "addr_cd", headerName: "주소", minWidth: 220, editable: true },
        { field: "dtl_addr_cd", headerName: "상세주소", minWidth: 220, editable: true },
        {
          field: "use_yn_cd",
          headerName: "사용여부",
          maxWidth: 95,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("CMM_USE_YN") },
          cellRenderer: "codeUseYnCellRenderer"
        },
        { field: "update_by", headerName: "수정자", minWidth: 95, editable: false },
        { field: "update_time", headerName: "수정일시", minWidth: 160, formatter: "datetime", editable: false }
      ]
    end
end
