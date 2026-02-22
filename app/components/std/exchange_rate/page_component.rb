class Std::ExchangeRate::PageComponent < Std::BasePageComponent
  private
    def collection_path(**) = helpers.std_exchange_rates_path(**)
    def member_path(_id, **) = helpers.std_exchange_rates_path(**)

    def batch_save_url
      helpers.batch_save_std_exchange_rates_path
    end

    def search_fields
      [
        { field: "ctry_cd", type: "popup", label: "국가", popup_type: "country", code_field: "ctry_cd", placeholder: "국가 선택" },
        {
          field: "fnc_or_cd",
          type: "select",
          label: "금융기관",
          options: common_code_options("STD_FIN_ORG", include_all: true, all_label: "전체"),
          include_blank: false
        },
        { field: "std_ymd", type: "date_picker", label: "기준일자" },
        {
          field: "anno_dgrcnt",
          type: "select",
          label: "고시회차",
          options: common_code_options("STD_ANNO_DGRCNT", include_all: true, all_label: "전체"),
          include_blank: false
        },
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
        { field: "ctry_cd", headerName: "국가코드", maxWidth: 100, editable: true },
        {
          field: "fnc_or_cd",
          headerName: "금융기관",
          minWidth: 120,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("STD_FIN_ORG") }
        },
        { field: "std_ymd", headerName: "기준일자", minWidth: 120, editable: true },
        {
          field: "anno_dgrcnt",
          headerName: "고시회차",
          minWidth: 130,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("STD_ANNO_DGRCNT") }
        },
        {
          field: "mon_cd",
          headerName: "통화",
          minWidth: 100,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("STD_MON_CODE") }
        },
        { field: "cash_buy", headerName: "현찰매입", minWidth: 100, editable: true, cellEditor: "agNumberCellEditor" },
        { field: "cash_sell", headerName: "현찰매도", minWidth: 100, editable: true, cellEditor: "agNumberCellEditor" },
        { field: "sendmoney_sndg", headerName: "송금보낼때", minWidth: 100, editable: true, cellEditor: "agNumberCellEditor" },
        { field: "sendmoney_rcvng", headerName: "송금받을때", minWidth: 100, editable: true, cellEditor: "agNumberCellEditor" },
        { field: "tc_buy", headerName: "TC매입", minWidth: 100, editable: true, cellEditor: "agNumberCellEditor" },
        { field: "fcur_check_sell", headerName: "외화수표매도", minWidth: 120, editable: true, cellEditor: "agNumberCellEditor" },
        { field: "tradg_std_rt", headerName: "매매기준율", minWidth: 110, editable: true, cellEditor: "agNumberCellEditor" },
        { field: "convmoney_rt", headerName: "환산율", minWidth: 120, editable: true, cellEditor: "agNumberCellEditor" },
        { field: "usd_conv_rt", headerName: "USD환산율", minWidth: 110, editable: true, cellEditor: "agNumberCellEditor" },
        {
          field: "if_yn_cd",
          headerName: "인터페이스여부",
          maxWidth: 110,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("CMM_USE_YN") },
          cellRenderer: "codeUseYnCellRenderer"
        },
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
