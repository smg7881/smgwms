class Std::Corporation::PageComponent < Std::BasePageComponent
  private
    def collection_path(**) = helpers.std_corporations_path(**)
    def member_path(id, **) = helpers.std_corporation_path(id, **)

    def master_batch_save_url
      helpers.batch_save_std_corporations_path
    end

    def country_list_url_template
      "/std/corporations/:id/country_infos.json"
    end

    def country_batch_url_template
      "/std/corporations/:id/batch_save_country_infos"
    end

    def search_fields
      [
        { field: "corp_cd", type: "input", label: "법인코드", placeholder: "코드 검색" },
        { field: "corp_nm", type: "input", label: "법인명", placeholder: "법인명 검색" },
        {
          field: "use_yn_cd",
          type: "select",
          label: "사용여부",
          options: common_code_options("CMM_USE_YN", include_all: true, all_label: "전체"),
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
        { field: "corp_cd", headerName: "법인코드", minWidth: 110, editable: true },
        { field: "corp_nm", headerName: "법인명", minWidth: 180, editable: true },
        { field: "indstype_cd", headerName: "종목", minWidth: 140, editable: true },
        { field: "bizcond_cd", headerName: "업태", minWidth: 140, editable: true },
        { field: "rptr_nm_cd", headerName: "대표자", minWidth: 140, editable: true },
        { field: "compreg_slip_cd", headerName: "사업자등록번호", minWidth: 130, editable: true },
        { field: "upper_corp_cd", headerName: "상위법인코드", minWidth: 110, editable: true },
        { field: "zip_cd", headerName: "우편번호", maxWidth: 100, editable: true },
        { field: "addr_cd", headerName: "주소", minWidth: 180, editable: true },
        { field: "dtl_addr_cd", headerName: "상세주소", minWidth: 180, editable: true },
        {
          field: "vat_sctn_cd",
          headerName: "부가세구분",
          minWidth: 130,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("STD_VAT_SCTN") }
        },
        {
          field: "use_yn_cd",
          headerName: "사용여부",
          maxWidth: 90,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("CMM_USE_YN") },
          cellRenderer: "codeUseYnCellRenderer"
        },
        { field: "update_by", headerName: "수정자", minWidth: 100, editable: false },
        { field: "update_time", headerName: "수정일시", minWidth: 160, formatter: "datetime", editable: false }
      ]
    end

    def country_columns
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
        { field: "seq", headerName: "순번", maxWidth: 90, editable: true, cellEditor: "agNumberCellEditor" },
        { field: "ctry_cd", headerName: "국가코드", minWidth: 110, editable: true },
        {
          field: "aply_mon_unit_cd",
          headerName: "통화코드",
          minWidth: 110,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("STD_MON_CODE") }
        },
        {
          field: "timezone_cd",
          headerName: "시간대",
          minWidth: 170,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("STD_TIMEZONE") }
        },
        { field: "std_time", headerName: "표준시간", minWidth: 100, editable: true },
        { field: "summer_time", headerName: "서머타임", minWidth: 110, editable: true },
        {
          field: "sys_lang_slc",
          headerName: "시스템언어",
          maxWidth: 100,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("STD_SYS_LANG") }
        },
        { field: "vat_rt", headerName: "부가세율", maxWidth: 100, editable: true, cellEditor: "agNumberCellEditor" },
        {
          field: "rpt_yn_cd",
          headerName: "대표국가여부",
          maxWidth: 115,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("CMM_USE_YN") },
          cellRenderer: "codeUseYnCellRenderer"
        },
        {
          field: "use_yn_cd",
          headerName: "사용여부",
          maxWidth: 90,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("CMM_USE_YN") },
          cellRenderer: "codeUseYnCellRenderer"
        }
      ]
    end
end
