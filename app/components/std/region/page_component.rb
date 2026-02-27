class Std::Region::PageComponent < Std::BasePageComponent
  private
    def collection_path(**) = helpers.std_regions_path(**)
    def member_path(_id, **) = helpers.std_regions_path(**)

    def batch_save_url
      helpers.batch_save_std_regions_path
    end

    def search_fields
      [
        { field: "corp_nm", type: "popup", label: "법인", popup_type: "corp", code_field: "corp_cd", placeholder: "법인 선택" },
        { field: "regn_keyword", type: "input", label: "권역", placeholder: "권역코드/권역명 입력" },
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
        {
          field: "corp_cd",
          headerName: "법인코드",
          minWidth: 120,
          editable: true,
          lookup_popup_type: "corp",
          lookup_code_field: "corp_cd",
          lookup_name_field: "corp_nm",
          lookup_popup_title: "법인 조회"
        },
        { field: "corp_nm", headerName: "법인명", minWidth: 170, editable: false },
        { field: "regn_cd", headerName: "권역코드", minWidth: 120, editable: true },
        { field: "regn_nm_cd", headerName: "권역명", minWidth: 170, editable: true },
        { field: "regn_eng_nm_cd", headerName: "권역영문명", minWidth: 170, editable: true },
        {
          field: "upper_regn_cd",
          headerName: "상위권역코드",
          minWidth: 130,
          editable: true,
          lookup_popup_type: "region",
          lookup_code_field: "upper_regn_cd",
          lookup_name_field: "upper_regn_nm",
          lookup_popup_title: "상위권역 조회"
        },
        { field: "upper_regn_nm", headerName: "상위권역명", minWidth: 170, editable: false },
        { field: "rmk_cd", headerName: "비고", minWidth: 220, editable: true },
        {
          field: "use_yn_cd",
          headerName: "사용여부",
          maxWidth: 95,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("CMM_USE_YN") },
          cellRenderer: "createStatusBadge", cellRendererParams: { trueLabel: "Y" }
        },
        { field: "update_by", headerName: "수정자", minWidth: 95, editable: false },
        { field: "update_time", headerName: "수정일시", minWidth: 160, formatter: "datetime", editable: false }
      ]
    end
end
