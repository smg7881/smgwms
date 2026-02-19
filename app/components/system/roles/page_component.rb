class System::Roles::PageComponent < System::BasePageComponent
  private
    def collection_path(**) = helpers.system_roles_path(**)
    def member_path(id, **) = helpers.system_role_path(id, **)

    def batch_save_url
      helpers.batch_save_system_roles_path
    end

    def search_fields
      [
        { field: "role_cd", type: "input", label: "역할코드", placeholder: "역할코드 검색.." },
        { field: "role_nm", type: "input", label: "역할명", placeholder: "역할명 검색.." },
        {
          field: "use_yn",
          type: "select",
          label: "사용여부",
          options: [
            { label: "전체", value: "" },
            { label: "사용", value: "Y" },
            { label: "미사용", value: "N" }
          ],
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
        { field: "role_cd", headerName: "역할코드", minWidth: 130, editable: true },
        { field: "role_nm", headerName: "역할명", minWidth: 180, editable: true },
        { field: "description", headerName: "설명", minWidth: 220, editable: true },
        {
          field: "use_yn",
          headerName: "사용여부",
          maxWidth: 110,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: %w[Y N] },
          cellRenderer: "codeUseYnCellRenderer"
        },
        { field: "update_by", headerName: "수정자", minWidth: 100, editable: false },
        { field: "update_time", headerName: "수정일시", minWidth: 170, formatter: "datetime", editable: false },
        { field: "create_by", headerName: "생성자", minWidth: 100, editable: false },
        { field: "create_time", headerName: "생성일시", minWidth: 170, formatter: "datetime", editable: false }
      ]
    end
end
