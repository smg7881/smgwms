class Std::ExchangeRate::PageComponent < Std::BasePageComponent
  private
    def collection_path(**) = helpers.std_exchange_rates_path(**)
    def member_path(_id, **) = helpers.std_exchange_rates_path(**)

    def batch_save_url
      helpers.batch_save_std_exchange_rates_path
    end

    def search_fields
      [
        { field: "ctry_cd", type: "popup", label: "Country", popup_type: "country", code_field: "ctry_cd", placeholder: "Select country" },
        {
          field: "fnc_or_cd",
          type: "select",
          label: "Financial Org",
          options: common_code_options("STD_FIN_ORG", include_all: true),
          include_blank: false
        },
        { field: "std_ymd", type: "date_picker", label: "Standard Date" },
        {
          field: "anno_dgrcnt",
          type: "select",
          label: "Announcement Degree",
          options: common_code_options("STD_ANNO_DGRCNT", include_all: true),
          include_blank: false
        },
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
        { field: "ctry_cd", headerName: "Country", maxWidth: 100, editable: true },
        {
          field: "fnc_or_cd",
          headerName: "Financial Org",
          minWidth: 120,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("STD_FIN_ORG") }
        },
        { field: "std_ymd", headerName: "Standard Date", minWidth: 120, editable: true },
        {
          field: "anno_dgrcnt",
          headerName: "Announcement Degree",
          minWidth: 130,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("STD_ANNO_DGRCNT") }
        },
        {
          field: "mon_cd",
          headerName: "Currency",
          minWidth: 100,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("STD_MON_CODE") }
        },
        { field: "cash_buy", headerName: "Cash Buy", minWidth: 100, editable: true, cellEditor: "agNumberCellEditor" },
        { field: "cash_sell", headerName: "Cash Sell", minWidth: 100, editable: true, cellEditor: "agNumberCellEditor" },
        { field: "sendmoney_sndg", headerName: "Send Money", minWidth: 100, editable: true, cellEditor: "agNumberCellEditor" },
        { field: "sendmoney_rcvng", headerName: "Receive Money", minWidth: 100, editable: true, cellEditor: "agNumberCellEditor" },
        { field: "tc_buy", headerName: "T/C Buy", minWidth: 100, editable: true, cellEditor: "agNumberCellEditor" },
        { field: "fcur_check_sell", headerName: "FC Check Sell", minWidth: 120, editable: true, cellEditor: "agNumberCellEditor" },
        { field: "tradg_std_rt", headerName: "Standard Rate", minWidth: 110, editable: true, cellEditor: "agNumberCellEditor" },
        { field: "convmoney_rt", headerName: "Conversion Rate", minWidth: 120, editable: true, cellEditor: "agNumberCellEditor" },
        { field: "usd_conv_rt", headerName: "USD Conv Rate", minWidth: 110, editable: true, cellEditor: "agNumberCellEditor" },
        {
          field: "if_yn_cd",
          headerName: "Interface Y/N",
          maxWidth: 110,
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
        },
        { field: "update_by", headerName: "Updated By", minWidth: 100, editable: false },
        { field: "update_time", headerName: "Updated At", minWidth: 160, formatter: "datetime", editable: false }
      ]
    end
end
