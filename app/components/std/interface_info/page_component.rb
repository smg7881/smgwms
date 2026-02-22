class Std::InterfaceInfo::PageComponent < Std::BasePageComponent
  private
    def collection_path(**) = helpers.std_interface_infos_path(**)
    def member_path(_id, **) = helpers.std_interface_infos_path(**)

    def batch_save_url
      helpers.batch_save_std_interface_infos_path
    end

    def search_fields
      [
        { field: "corp_cd", type: "popup", label: "법인", popup_type: "corp", code_field: "corp_cd", placeholder: "법인 선택" },
        {
          field: "if_sctn_cd",
          type: "select",
          label: "인터페이스구분",
          options: common_code_options("STD_IF_SCTN", include_all: true, all_label: "전체"),
          include_blank: false
        },
        { field: "if_nm_cd", type: "input", label: "인터페이스명", placeholder: "인터페이스명 검색" },
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
        { field: "corp_cd", headerName: "법인코드", minWidth: 110, editable: true },
        { field: "if_cd", headerName: "인터페이스코드", minWidth: 120, editable: true },
        {
          field: "if_meth_cd",
          headerName: "인터페이스방식",
          minWidth: 110,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("STD_IF_METHOD") }
        },
        {
          field: "if_sctn_cd",
          headerName: "인터페이스구분",
          minWidth: 110,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("STD_IF_SCTN") }
        },
        { field: "if_nm_cd", headerName: "인터페이스명", minWidth: 170, editable: true },
        {
          field: "send_sys_cd",
          headerName: "송신시스템",
          minWidth: 120,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("STD_SYS_SCTN") }
        },
        {
          field: "rcv_sys_cd",
          headerName: "수신시스템",
          minWidth: 120,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("STD_SYS_SCTN") }
        },
        {
          field: "rcv_sctn_cd",
          headerName: "송수신구분",
          minWidth: 120,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("STD_SEND_RECV_SCTN") }
        },
        { field: "if_bzac_cd", headerName: "거래처코드", minWidth: 120, editable: true },
        { field: "bzac_nm", headerName: "거래처명", minWidth: 160, editable: true },
        { field: "bzac_sys_nm_cd", headerName: "거래처시스템", minWidth: 160, editable: true },
        { field: "if_desc_cd", headerName: "설명", minWidth: 220, editable: true },
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
