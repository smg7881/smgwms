class Std::Country::PageComponent < Std::BasePageComponent
  private
    def collection_path(**) = helpers.std_countries_path(**)
    def member_path(_id, **) = helpers.std_countries_path(**)

    def batch_save_url
      helpers.batch_save_std_countries_path
    end

    def search_fields
      [
        { field: "corp_nm", type: "popup", label: "법인", popup_type: "corp", code_field: "corp_cd", placeholder: "법인 선택" },
        { field: "ctry_nm", type: "popup", label: "국가", popup_type: "country", code_field: "ctry_cd", placeholder: "국가 선택" },
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
        { field: "ctry_cd", headerName: "국가코드", minWidth: 110, editable: true },
        { field: "ctry_nm", headerName: "국가명", minWidth: 150, editable: true },
        { field: "ctry_eng_nm", headerName: "국가영문명", minWidth: 170, editable: true },
        {
          field: "ctry_ar_cd",
          headerName: "국가지역코드",
          minWidth: 120,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("STD_CTRY_AREA") }
        },
        { field: "ctry_telno", headerName: "전화번호", minWidth: 100, editable: true },
        { field: "corp_cd", headerName: "법인코드", minWidth: 110, editable: true },
        { field: "corp_nm", headerName: "법인명", minWidth: 140, editable: true },
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
