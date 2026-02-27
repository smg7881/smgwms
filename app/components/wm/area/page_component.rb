class Wm::Area::PageComponent < Wm::BasePageComponent
  private
    def collection_path(**) = helpers.wm_area_index_path(**)
    def member_path(_id, **) = helpers.wm_area_index_path(**)

    def batch_save_url
      helpers.batch_save_wm_area_index_path
    end

    def search_fields
      [
        {
          field: "workpl_cd",
          type: "select",
          label: "작업장",
          options: record_options(WmWorkplace, code_field: :workpl_cd, name_field: :workpl_nm, include_all: true),
          include_blank: false
        },
        { field: "area_nm", type: "input", label: "AREA명", placeholder: "AREA명 검색.." },
        {
          field: "use_yn",
          type: "select",
          label: "사용여부",
          options: common_code_options("CMM_USE_YN", include_all: true),
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
          field: "workpl_cd",
          headerName: "작업장코드",
          minWidth: 140,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: record_values(WmWorkplace, code_field: :workpl_cd) }
        },
        { field: "workpl_nm", headerName: "작업장명", minWidth: 180, editable: false },
        { field: "area_cd", headerName: "AREA코드", minWidth: 140, editable: true },
        { field: "area_nm", headerName: "AREA명", minWidth: 180, editable: true },
        { field: "area_desc", headerName: "AREA설명", minWidth: 240, editable: true },
        {
          field: "use_yn",
          headerName: "사용여부",
          maxWidth: 110,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("CMM_USE_YN") },
          cellRenderer: "createStatusBadge", cellRendererParams: { trueLabel: "Y" }
        },
        { field: "update_by", headerName: "수정자", minWidth: 100, editable: false },
        { field: "update_time", headerName: "수정일시", minWidth: 170, formatter: "datetime", editable: false },
        { field: "create_by", headerName: "생성자", minWidth: 100, editable: false },
        { field: "create_time", headerName: "생성일시", minWidth: 170, formatter: "datetime", editable: false }
      ]
    end

end
