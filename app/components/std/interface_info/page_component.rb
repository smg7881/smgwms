class Std::InterfaceInfo::PageComponent < Std::BasePageComponent
  private
    def collection_path(**) = helpers.std_interface_infos_path(**)
    def member_path(_id, **) = helpers.std_interface_infos_path(**)

    def batch_save_url
      helpers.batch_save_std_interface_infos_path
    end

    def search_fields
      [
        { field: "corp_cd", type: "popup", label: "Corporation", popup_type: "corp", code_field: "corp_cd", placeholder: "Select corporation" },
        {
          field: "if_sctn_cd",
          type: "select",
          label: "Interface Section",
          options: common_code_options("STD_IF_SCTN", include_all: true),
          include_blank: false
        },
        { field: "if_nm_cd", type: "input", label: "Interface Name", placeholder: "Search interface name" },
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
        { field: "corp_cd", headerName: "Corp Code", minWidth: 110, editable: true },
        { field: "if_cd", headerName: "Interface Code", minWidth: 120, editable: true },
        {
          field: "if_meth_cd",
          headerName: "Method",
          minWidth: 110,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("STD_IF_METHOD") }
        },
        {
          field: "if_sctn_cd",
          headerName: "Section",
          minWidth: 110,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("STD_IF_SCTN") }
        },
        { field: "if_nm_cd", headerName: "Interface Name", minWidth: 170, editable: true },
        {
          field: "send_sys_cd",
          headerName: "Send System",
          minWidth: 120,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("STD_SYS_SCTN") }
        },
        {
          field: "rcv_sys_cd",
          headerName: "Receive System",
          minWidth: 120,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("STD_SYS_SCTN") }
        },
        {
          field: "rcv_sctn_cd",
          headerName: "Send/Receive",
          minWidth: 120,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("STD_SEND_RECV_SCTN") }
        },
        { field: "if_bzac_cd", headerName: "Partner Code", minWidth: 120, editable: true },
        { field: "bzac_nm", headerName: "Partner Name", minWidth: 160, editable: true },
        { field: "bzac_sys_nm_cd", headerName: "Partner System", minWidth: 160, editable: true },
        { field: "if_desc_cd", headerName: "Description", minWidth: 220, editable: true },
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
