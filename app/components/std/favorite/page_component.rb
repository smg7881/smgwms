class Std::Favorite::PageComponent < Std::BasePageComponent
  private
    def collection_path(**) = helpers.std_favorites_path(**)
    def member_path(_id, **) = helpers.std_favorites_path(**)

    def batch_save_url
      helpers.batch_save_std_favorites_path
    end

    def group_list_url
      helpers.groups_std_favorites_path(format: :json)
    end

    def group_batch_save_url
      helpers.batch_save_groups_std_favorites_path
    end

    def search_fields
      [
        { field: "user_nm", type: "popup", label: "User", popup_type: "user", code_field: "user_id_code", placeholder: "Select user" },
        { field: "menu_nm", type: "input", label: "Menu Name", placeholder: "Search menu name" },
        {
          field: "use_yn",
          type: "select",
          label: "Use Y/N",
          options: common_code_options("CMM_USE_YN", include_all: true),
          include_blank: false
        }
      ]
    end

    def favorite_columns
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
        { field: "user_id_code", headerName: "User ID", minWidth: 110, editable: true },
        {
          field: "menu_cd",
          headerName: "Menu Code",
          minWidth: 120,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: menu_code_values }
        },
        { field: "menu_nm", headerName: "Menu Name", minWidth: 180, editable: true },
        { field: "user_favor_menu_grp", headerName: "Favorite Group", minWidth: 130, editable: true },
        { field: "sort_seq", headerName: "Sort Seq", maxWidth: 95, editable: true, cellEditor: "agNumberCellEditor" },
        {
          field: "use_yn",
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

    def group_columns
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
        { field: "user_id_code", headerName: "User ID", minWidth: 120, editable: true },
        { field: "group_nm", headerName: "Group Name", minWidth: 180, editable: true },
        {
          field: "use_yn",
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

    def menu_code_values
      AdmMenu.active.where(menu_type: "MENU").ordered.pluck(:menu_cd)
    end
end
