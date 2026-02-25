class Wm::GrPrars::PageComponent < Wm::BasePageComponent
  def initialize(query_params:, selected_gr_prar_no: nil)
    super(query_params: query_params)
    @selected_gr_prar_no = selected_gr_prar_no.presence
  end

  private
    attr_reader :selected_gr_prar_no

    def collection_path(**) = helpers.wm_gr_prars_path(**)
    def member_path(id, **) = helpers.wm_gr_prar_path(id, **)

    def detail_list_url_template
      "/wm/gr_prars/:gr_prar_id/details.json"
    end

    def exec_result_list_url_template
      "/wm/gr_prars/:gr_prar_id/exec_results.json"
    end

    def save_url_template
      "/wm/gr_prars/:gr_prar_id/save_gr"
    end

    def confirm_url_template
      "/wm/gr_prars/:gr_prar_id/confirm"
    end

    def cancel_url_template
      "/wm/gr_prars/:gr_prar_id/cancel"
    end

    def staged_locations_url
      helpers.staged_locations_wm_gr_prars_path(format: :json)
    end

    def selected_master_label
      selected_gr_prar_no.present? ? "선택 입고예정: #{selected_gr_prar_no}" : "입고예정을 먼저 선택하세요."
    end

    def search_fields
      today = Time.current.strftime("%Y-%m-%d")
      [
        {
          field: "workpl_cd", type: "popup", label: "작업장", required: true,
          popup_type: "workplace", code_field: "workpl_cd", name_field: "workpl_nm",
          placeholder: "작업장 선택"
        },
        {
          field: "cust_cd", type: "popup", label: "고객",
          popup_type: "customer", code_field: "cust_cd", name_field: "cust_nm",
          placeholder: "고객 선택"
        },
        {
          field: "gr_type_cd", type: "select", label: "입고유형",
          options: common_code_options("152", include_all: true),
          include_blank: false
        },
        {
          field: "gr_stat_cd", type: "select", label: "입고상태",
          options: common_code_options("153", include_all: true),
          include_blank: false
        },
        {
          field: "prar_ymd", type: "date_range", label: "예정일자",
          start_field: "prar_ymd_from", end_field: "prar_ymd_to",
          value: [ today, today ]
        },
        {
          field: "gr_ymd", type: "date_picker", label: "입고일자"
        },
        {
          field: "item_cd", type: "popup", label: "아이템",
          popup_type: "item", code_field: "item_cd", name_field: "item_nm",
          placeholder: "아이템 선택"
        },
        {
          field: "ord_no", type: "input", label: "오더번호",
          placeholder: "오더번호 입력"
        },
        {
          field: "dptar_type_cd", type: "select", label: "출발지유형",
          options: common_code_options("CMM_DPTAR_TYPE", include_all: true),
          include_blank: false
        },
        {
          field: "dptar_cd", type: "popup", label: "출발지",
          popup_type: "departure", code_field: "dptar_cd", name_field: "dptar_nm",
          placeholder: "출발지 선택"
        },
        {
          field: "car_no", type: "input", label: "차량번호",
          placeholder: "차량번호 입력"
        }
      ]
    end

    def master_columns
      [
        { field: "gr_prar_no",    headerName: "입고예정번호", minWidth: 160, editable: false },
        { field: "cust_cd",       headerName: "고객",        minWidth: 120, editable: false },
        {
          field: "gr_type_cd",    headerName: "입고유형",     minWidth: 120, editable: false,
          cellRenderer: "commonCodeCellRenderer",
          cellRendererParams: { codeGroup: "152" }
        },
        {
          field: "ord_reason_cd", headerName: "오더사유",     minWidth: 130, editable: false,
          cellRenderer: "commonCodeCellRenderer",
          cellRendererParams: { codeGroup: "87" }
        },
        {
          field: "gr_stat_cd",    headerName: "입고상태",     minWidth: 110, editable: false,
          cellRenderer: "statusBadgeCellRenderer",
          cellRendererParams: { codeGroup: "153" }
        },
        { field: "prar_ymd",      headerName: "입고예정일자", minWidth: 130, editable: false },
        { field: "gr_ymd",        headerName: "입고일자",     minWidth: 120, editable: false },
        { field: "gr_hms",        headerName: "입고시간",     minWidth: 100, editable: false },
        { field: "ord_no",        headerName: "오더번호",     minWidth: 140, editable: false },
        { field: "rel_gi_ord_no", headerName: "관련출고오더", minWidth: 150, editable: false },
        { field: "dptar_cd",      headerName: "출발지",       minWidth: 120, editable: false },
        { field: "car_no",        headerName: "차량번호",     minWidth: 120, editable: true },
        { field: "driver_nm",     headerName: "기사명",       minWidth: 100, editable: false },
        { field: "driver_telno",  headerName: "기사전화번호", minWidth: 140, editable: true },
        { field: "transco_cd",    headerName: "운송사",       minWidth: 120, editable: false },
        { field: "rmk",           headerName: "비고",         minWidth: 200, editable: true }
      ]
    end

    def detail_columns
      [
        { field: "lineno",       headerName: "라인번호",   minWidth: 90,  editable: false },
        { field: "item_cd",      headerName: "아이템코드", minWidth: 140, editable: false },
        { field: "item_nm",      headerName: "아이템명",   minWidth: 200, editable: false },
        { field: "unit_cd",      headerName: "단위",       minWidth: 80,  editable: false },
        { field: "gr_prar_qty",  headerName: "입고예정수량", minWidth: 120, editable: false, type: "numericColumn" },
        { field: "gr_loc_cd",    headerName: "입고로케이션", minWidth: 140, editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: [] } },
        { field: "gr_qty",       headerName: "입고물량",   minWidth: 110, editable: true, type: "numericColumn" },
        { field: "gr_rslt_qty",  headerName: "입고실적물량", minWidth: 120, editable: false, type: "numericColumn" },
        { field: "gr_ymd",       headerName: "입고일자",   minWidth: 110, editable: false },
        { field: "gr_hms",       headerName: "입고시간",   minWidth: 100, editable: false },
        { field: "stock_attr_col01", headerName: "재고속성01", minWidth: 110, editable: true },
        { field: "stock_attr_col02", headerName: "재고속성02", minWidth: 110, editable: true },
        { field: "stock_attr_col03", headerName: "재고속성03", minWidth: 110, editable: true },
        { field: "stock_attr_col04", headerName: "재고속성04", minWidth: 110, editable: true },
        { field: "stock_attr_col05", headerName: "재고속성05", minWidth: 110, editable: true },
        { field: "stock_attr_col06", headerName: "재고속성06", minWidth: 110, editable: true },
        { field: "stock_attr_col07", headerName: "재고속성07", minWidth: 110, editable: true },
        { field: "stock_attr_col08", headerName: "재고속성08", minWidth: 110, editable: true },
        { field: "stock_attr_col09", headerName: "재고속성09", minWidth: 110, editable: true },
        { field: "stock_attr_col10", headerName: "재고속성10", minWidth: 110, editable: true },
        { field: "rmk",          headerName: "비고",       minWidth: 200, editable: true }
      ]
    end

    def exec_result_columns
      [
        { field: "lineno",          headerName: "라인번호",  minWidth: 90,  editable: false },
        { field: "seq",             headerName: "순번",      minWidth: 80,  editable: false },
        {
          field: "exce_rslt_type",  headerName: "처리유형",  minWidth: 100, editable: false,
          cellRenderer: "commonCodeCellRenderer",
          cellRendererParams: { codeGroup: "113" }
        },
        { field: "item_cd",         headerName: "아이템코드", minWidth: 140, editable: false },
        { field: "to_loc",          headerName: "입고로케이션", minWidth: 130, editable: false },
        { field: "rslt_qty",        headerName: "입고물량",  minWidth: 110, editable: false, type: "numericColumn" },
        { field: "basis_unit_cd",   headerName: "단위",      minWidth: 80,  editable: false },
        { field: "exce_rslt_ymd",   headerName: "입고일자",  minWidth: 110, editable: false },
        { field: "exce_rslt_hms",   headerName: "입고시간",  minWidth: 100, editable: false },
        { field: "stock_attr_col01", headerName: "재고속성01", minWidth: 110, editable: false },
        { field: "stock_attr_col02", headerName: "재고속성02", minWidth: 110, editable: false },
        { field: "stock_attr_col03", headerName: "재고속성03", minWidth: 110, editable: false },
        { field: "stock_attr_col04", headerName: "재고속성04", minWidth: 110, editable: false },
        { field: "stock_attr_col05", headerName: "재고속성05", minWidth: 110, editable: false },
        { field: "stock_attr_col06", headerName: "재고속성06", minWidth: 110, editable: false },
        { field: "stock_attr_col07", headerName: "재고속성07", minWidth: 110, editable: false },
        { field: "stock_attr_col08", headerName: "재고속성08", minWidth: 110, editable: false },
        { field: "stock_attr_col09", headerName: "재고속성09", minWidth: 110, editable: false },
        { field: "stock_attr_col10", headerName: "재고속성10", minWidth: 110, editable: false }
      ]
    end
end
