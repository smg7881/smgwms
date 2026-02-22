class Std::Holiday::PageComponent < Std::BasePageComponent
  private
    def collection_path(**) = helpers.std_holidays_path(**)
    def member_path(_id, **) = helpers.std_holidays_path(**)

    def batch_save_url
      helpers.batch_save_std_holidays_path
    end

    def generate_weekends_url
      helpers.generate_weekends_std_holidays_path
    end

    def search_fields
      [
        {
          field: "ctry_cd",
          type: "select",
          label: "국가코드",
          options: country_options,
          include_blank: false
        },
        { field: "year", type: "input", label: "년도", placeholder: "YYYY" },
        { field: "month", type: "input", label: "월", placeholder: "MM" }
      ]
    end

    def country_options
      options = [ { label: "전체", value: "" } ]
      options + StdCountry.active.ordered.map { |row| { label: "#{row.ctry_nm} (#{row.ctry_cd})", value: row.ctry_cd } }
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
        { field: "ctry_cd", headerName: "국가코드", minWidth: 90, editable: true },
        { field: "ymd", headerName: "일자", minWidth: 120, editable: true },
        { field: "holiday_nm_cd", headerName: "공휴일명", minWidth: 170, editable: true },
        {
          field: "sat_yn_cd",
          headerName: "토요일",
          maxWidth: 90,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("CMM_USE_YN") },
          cellRenderer: "codeUseYnCellRenderer"
        },
        {
          field: "sunday_yn_cd",
          headerName: "일요일",
          maxWidth: 90,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("CMM_USE_YN") },
          cellRenderer: "codeUseYnCellRenderer"
        },
        {
          field: "clsdy_yn_cd",
          headerName: "휴무일",
          maxWidth: 90,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("CMM_USE_YN") },
          cellRenderer: "codeUseYnCellRenderer"
        },
        {
          field: "asmt_holday_yn_cd",
          headerName: "지정휴일",
          maxWidth: 95,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("CMM_USE_YN") },
          cellRenderer: "codeUseYnCellRenderer"
        },
        {
          field: "event_day_yn_cd",
          headerName: "행사일",
          maxWidth: 90,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("CMM_USE_YN") },
          cellRenderer: "codeUseYnCellRenderer"
        },
        { field: "rmk_cd", headerName: "비고", minWidth: 220, editable: true }
      ]
    end
end
