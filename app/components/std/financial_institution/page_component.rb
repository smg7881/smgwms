class Std::FinancialInstitution::PageComponent < Std::BasePageComponent
  private
    def collection_path(**) = helpers.std_financial_institutions_path(**)
    def member_path(_id, **) = helpers.std_financial_institutions_path(**)

    def batch_save_url
      helpers.batch_save_std_financial_institutions_path
    end

    def search_fields
      [
        { field: "fnc_or_nm", type: "input", label: "금융기관명", placeholder: "금융기관명 검색" },
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
        { field: "fnc_or_cd", headerName: "금융기관코드", minWidth: 130, editable: true },
        { field: "fnc_or_nm", headerName: "금융기관명", minWidth: 170, editable: true },
        { field: "fnc_or_eng_nm", headerName: "금융기관영문명", minWidth: 190, editable: true },
        { field: "ctry_cd", headerName: "국가코드", minWidth: 100, editable: true },
        {
          field: "ctry_nm",
          headerName: "국가",
          minWidth: 140,
          editable: true,
          lookup_popup_type: "country",
          lookup_code_field: "ctry_cd",
          lookup_name_field: "ctry_nm",
          lookup_popup_title: "국가 조회"
        },
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
