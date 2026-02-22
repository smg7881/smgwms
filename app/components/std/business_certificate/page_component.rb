class Std::BusinessCertificate::PageComponent < Std::BasePageComponent
  private
    def collection_path(**) = helpers.std_business_certificates_path(**)
    def member_path(_id, **) = helpers.std_business_certificates_path(**)

    def batch_save_url
      helpers.batch_save_std_business_certificates_path
    end

    def search_fields
      [
        { field: "bzac_cd", type: "input", label: "Client Code", placeholder: "Search code" },
        { field: "bzac_nm", type: "popup", label: "Client", popup_type: "client", code_field: "bzac_cd", placeholder: "Select client" },
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
        { field: "bzac_cd", headerName: "Client Code", minWidth: 110, editable: true },
        { field: "bzac_nm", headerName: "Client Name", minWidth: 160, editable: true },
        { field: "compreg_slip", headerName: "Business Reg No", minWidth: 130, editable: true },
        {
          field: "bizman_yn_cd",
          headerName: "Business Type",
          minWidth: 120,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("STD_BIZMAN_YN") }
        },
        { field: "store_nm_cd", headerName: "Store Name", minWidth: 150, editable: true },
        { field: "rptr_nm_cd", headerName: "Representative", minWidth: 130, editable: true },
        { field: "corp_reg_no_cd", headerName: "Corp Reg No", minWidth: 130, editable: true },
        { field: "bizcond_cd", headerName: "Business Condition", minWidth: 140, editable: true },
        { field: "indstype_cd", headerName: "Industry Type", minWidth: 140, editable: true },
        {
          field: "dup_bzac_yn_cd",
          headerName: "Dup Client",
          maxWidth: 100,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("CMM_USE_YN") },
          cellRenderer: "codeUseYnCellRenderer"
        },
        { field: "zip_cd", headerName: "Zip", maxWidth: 100, editable: true },
        { field: "zipaddr_cd", headerName: "Address", minWidth: 180, editable: true },
        { field: "dtl_addr_cd", headerName: "Address Detail", minWidth: 180, editable: true },
        { field: "clbiz_ymd", headerName: "Closed Date", minWidth: 120, editable: true },
        { field: "attached_file_nm", headerName: "Attachment", minWidth: 140, editable: true },
        { field: "rmk", headerName: "Remark", minWidth: 200, editable: true },
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
