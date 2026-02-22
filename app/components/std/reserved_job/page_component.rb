class Std::ReservedJob::PageComponent < Std::BasePageComponent
  private
    def collection_path(**) = helpers.std_reserved_jobs_path(**)
    def member_path(_id, **) = helpers.std_reserved_jobs_path(**)

    def batch_save_url
      helpers.batch_save_std_reserved_jobs_path
    end

    def search_fields
      [
        {
          field: "sys_sctn_cd",
          type: "select",
          label: "시스템구분",
          options: common_code_options("STD_SYS_SCTN", include_all: true, all_label: "전체"),
          include_blank: false
        },
        { field: "rsv_work_nm_cd", type: "input", label: "예약작업명", placeholder: "예약작업명 검색" },
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
          field: "sys_sctn_cd",
          headerName: "시스템구분",
          minWidth: 120,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("STD_SYS_SCTN") }
        },
        { field: "rsv_work_no", headerName: "예약작업번호", minWidth: 120, editable: true },
        { field: "rel_menu_cd", headerName: "관련메뉴코드", minWidth: 120, editable: true },
        { field: "rel_menu_nm", headerName: "관련메뉴명", minWidth: 150, editable: true },
        { field: "rsv_work_nm_cd", headerName: "예약작업명", minWidth: 170, editable: true },
        { field: "rsv_work_desc_cd", headerName: "예약작업설명", minWidth: 220, editable: true },
        { field: "rel_pgm_cd", headerName: "관련프로그램코드", minWidth: 140, editable: true },
        { field: "rel_pgm_nm", headerName: "관련프로그램명", minWidth: 150, editable: true },
        {
          field: "pgm_sctn_cd",
          headerName: "프로그램구분",
          minWidth: 120,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("STD_PGM_SCTN") }
        },
        {
          field: "rsv_work_cycle_cd",
          headerName: "예약작업주기",
          minWidth: 130,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("STD_RSV_WORK_CYCLE") }
        },
        { field: "hms_unit_min", headerName: "분단위", maxWidth: 100, editable: true, cellEditor: "agNumberCellEditor" },
        { field: "rmk_cd", headerName: "비고", minWidth: 180, editable: true },
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
end
