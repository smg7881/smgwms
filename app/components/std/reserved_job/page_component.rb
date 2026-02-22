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
          label: "System Section",
          options: common_code_options("STD_SYS_SCTN", include_all: true),
          include_blank: false
        },
        { field: "rsv_work_nm_cd", type: "input", label: "Reserved Job Name", placeholder: "Search job name" },
        {
          field: "use_yn_cd",
          type: "select",
          label: "Use Y/N",
          options: common_code_options("CMM_USE_YN", include_all: true),
          include_blank: false
        }
      ]
    end

    def columns
      [
        {
          field: "__row_status",
          headerName: "Status",
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
          headerName: "System Section",
          minWidth: 120,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("STD_SYS_SCTN") }
        },
        { field: "rsv_work_no", headerName: "Reserved Job No", minWidth: 120, editable: true },
        { field: "rel_menu_cd", headerName: "Related Menu Code", minWidth: 120, editable: true },
        { field: "rel_menu_nm", headerName: "Related Menu Name", minWidth: 150, editable: true },
        { field: "rsv_work_nm_cd", headerName: "Reserved Job Name", minWidth: 170, editable: true },
        { field: "rsv_work_desc_cd", headerName: "Reserved Job Desc", minWidth: 220, editable: true },
        { field: "rel_pgm_cd", headerName: "Related Program Code", minWidth: 140, editable: true },
        { field: "rel_pgm_nm", headerName: "Related Program Name", minWidth: 150, editable: true },
        {
          field: "pgm_sctn_cd",
          headerName: "Program Section",
          minWidth: 120,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("STD_PGM_SCTN") }
        },
        {
          field: "rsv_work_cycle_cd",
          headerName: "Reserved Job Cycle",
          minWidth: 130,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("STD_RSV_WORK_CYCLE") }
        },
        { field: "hms_unit_min", headerName: "Minute Unit", maxWidth: 100, editable: true, cellEditor: "agNumberCellEditor" },
        { field: "rmk_cd", headerName: "Remark", minWidth: 180, editable: true },
        {
          field: "use_yn_cd",
          headerName: "Use Y/N",
          maxWidth: 90,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("CMM_USE_YN") },
          cellRenderer: "codeUseYnCellRenderer"
        },
        { field: "update_by", headerName: "Updated By", minWidth: 100, editable: false },
        { field: "update_time", headerName: "Updated At", minWidth: 160, formatter: "datetime", editable: false }
      ]
    end
end
