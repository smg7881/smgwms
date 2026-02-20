class Wm::Workplace::PageComponent < Wm::BasePageComponent
  private
    def collection_path(**) = helpers.wm_workplace_index_path(**)
    def member_path(_id, **) = helpers.wm_workplace_index_path(**)

    def batch_save_url
      helpers.batch_save_wm_workplace_index_path
    end

    def search_fields
      [
        { field: "workpl", type: "input", label: "작업장", placeholder: "작업장코드/명 검색.." },
        {
          field: "workpl_type",
          type: "select",
          label: "작업장유형",
          options: common_code_options("WORKPL_TYPE", include_all: true),
          include_blank: false
        },
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
        { field: "workpl_cd", headerName: "작업장코드", minWidth: 140, editable: true },
        { field: "workpl_nm", headerName: "작업장명", minWidth: 180, editable: true },
        {
          field: "workpl_type",
          headerName: "작업장유형",
          minWidth: 130,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("WORKPL_TYPE") }
        },
        { field: "nation_cd", headerName: "국가", minWidth: 100, editable: true },
        { field: "zip_cd", headerName: "우편번호", minWidth: 120, editable: true },
        { field: "addr", headerName: "주소", minWidth: 220, editable: true },
        { field: "addr_dtl", headerName: "상세주소", minWidth: 220, editable: true },
        { field: "tel_no", headerName: "전화번호", minWidth: 130, editable: true },
        {
          field: "use_yn",
          headerName: "사용여부",
          maxWidth: 110,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("CMM_USE_YN") },
          cellRenderer: "codeUseYnCellRenderer"
        },
        { field: "update_by", headerName: "수정자", minWidth: 100, editable: false },
        { field: "update_time", headerName: "수정일시", minWidth: 170, formatter: "datetime", editable: false },
        { field: "create_by", headerName: "생성자", minWidth: 100, editable: false },
        { field: "create_time", headerName: "생성일시", minWidth: 170, formatter: "datetime", editable: false }
      ]
    end
end
