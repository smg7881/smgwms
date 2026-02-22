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
        { field: "corp_cd", type: "input", label: "Corporation Code", placeholder: "Search code" },
        { field: "corp_nm", type: "input", label: "Corporation Name", placeholder: "Search name" },
        {
          field: "use_yn_cd",
          type: "select",
          label: "Use Y/N",
          options: common_code_options("CMM_USE_YN", include_all: true),
          include_blank: false
        }
      ]
    end

    def master_columns
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
        { field: "corp_nm", headerName: "Corp Name", minWidth: 180, editable: true },
        { field: "indstype_cd", headerName: "Industry", minWidth: 140, editable: true },
        { field: "bizcond_cd", headerName: "Business Type", minWidth: 140, editable: true },
        { field: "rptr_nm_cd", headerName: "Representative", minWidth: 140, editable: true },
        { field: "compreg_slip_cd", headerName: "Business Reg No", minWidth: 130, editable: true },
        { field: "upper_corp_cd", headerName: "Upper Corp", minWidth: 110, editable: true },
        { field: "zip_cd", headerName: "Zip", maxWidth: 100, editable: true },
        { field: "addr_cd", headerName: "Address", minWidth: 180, editable: true },
        { field: "dtl_addr_cd", headerName: "Address Detail", minWidth: 180, editable: true },
        {
          field: "vat_sctn_cd",
          headerName: "VAT Section",
          minWidth: 130,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("STD_VAT_SCTN") }
        },
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

    def country_columns
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
        { field: "seq", headerName: "Seq", maxWidth: 90, editable: true, cellEditor: "agNumberCellEditor" },
        { field: "ctry_cd", headerName: "Country", minWidth: 110, editable: true },
        {
          field: "aply_mon_unit_cd",
          headerName: "Currency",
          minWidth: 110,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("STD_MON_CODE") }
        },
        {
          field: "timezone_cd",
          headerName: "Time Zone",
          minWidth: 170,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("STD_TIMEZONE") }
        },
        { field: "std_time", headerName: "Std Time", minWidth: 100, editable: true },
        { field: "summer_time", headerName: "Summer Time", minWidth: 110, editable: true },
        {
          field: "sys_lang_slc",
          headerName: "Language",
          maxWidth: 100,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("STD_SYS_LANG") }
        },
        { field: "vat_rt", headerName: "VAT Rate", maxWidth: 100, editable: true, cellEditor: "agNumberCellEditor" },
        {
          field: "rpt_yn_cd",
          headerName: "Representative",
          maxWidth: 115,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("CMM_USE_YN") },
          cellRenderer: "codeUseYnCellRenderer"
        },
        {
          field: "use_yn_cd",
          headerName: "Use Y/N",
          maxWidth: 90,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("CMM_USE_YN") },
          cellRenderer: "codeUseYnCellRenderer"
        }
      ]
    end
end
