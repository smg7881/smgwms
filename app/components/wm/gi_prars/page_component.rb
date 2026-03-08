class Wm::GiPrars::PageComponent < Wm::BasePageComponent
  def initialize(query_params:, selected_gi_prar_no: nil)
    super(query_params: query_params)
    @selected_gi_prar_no = selected_gi_prar_no.presence
  end

  private
    attr_reader :selected_gi_prar_no

    def collection_path(**) = helpers.wm_gi_prars_path(**)
    def member_path(id, **) = helpers.wm_gi_prar_path(id, **)
    def detail_collection_path(id, **) = helpers.wm_gi_prar_details_path(id, **)

    def detail_grid_url
      if selected_gi_prar_no.present?
        detail_collection_path(selected_gi_prar_no, format: :json)
      else
        nil
      end
    end

    def master_batch_save_url
      helpers.batch_save_wm_gi_prars_path
    end

    def detail_batch_save_url_template
      "/wm/gi_prars/:gi_prar_id/details/batch_save"
    end

    def detail_list_url_template
      "/wm/gi_prars/:gi_prar_id/details.json"
    end

    def pick_list_url_template
      "/wm/gi_prars/:gi_prar_id/picks.json"
    end

    def assign_url_template
      "/wm/gi_prars/:gi_prar_id/assign"
    end

    def pick_url_template
      "/wm/gi_prars/:gi_prar_id/pick"
    end

    def confirm_url_template
      "/wm/gi_prars/:gi_prar_id/confirm"
    end

    def cancel_url_template
      "/wm/gi_prars/:gi_prar_id/cancel"
    end

    def selected_master_label
      if selected_gi_prar_no.present?
        "선택 출고예정: #{selected_gi_prar_no}"
      else
        "출고예정을 먼저 선택하세요."
      end
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
          field: "gi_type_cd", type: "select", label: "출고유형",
          options: common_code_options("154", include_all: true),
          include_blank: false
        },
        {
          field: "gi_stat_cd", type: "select", label: "출고상태",
          options: common_code_options("155", include_all: true),
          include_blank: false
        },
        {
          field: "idct_ymd", type: "date_range", label: "지시일자",
          start_field: "idct_ymd_from", end_field: "idct_ymd_to",
          value: [ today, today ]
        },
        {
          field: "gi_ymd", type: "date_picker", label: "출고일자"
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
          field: "asign_no", type: "input", label: "배차번호",
          placeholder: "배차번호 입력"
        },
        {
          field: "car_no", type: "input", label: "차량번호",
          placeholder: "차량번호 입력"
        }
      ]
    end

    def master_columns
      [
        { field: "gi_prar_no", headerName: "출고예정번호", minWidth: 160, editable: false },
        { field: "cust_cd", headerName: "고객", minWidth: 120, editable: false },
        {
          field: "gi_type_cd", headerName: "출고유형", minWidth: 120, editable: false,
          cellRenderer: "commonCodeCellRenderer",
          cellRendererParams: { codeGroup: "154" }
        },
        { field: "asign_no", headerName: "배차번호", minWidth: 130, editable: false },
        {
          field: "gi_stat_cd", headerName: "출고상태", minWidth: 120, editable: false,
          cellRenderer: "statusBadgeCellRenderer",
          cellRendererParams: { codeGroup: "155" }
        },
        { field: "idct_ymd", headerName: "지시일자", minWidth: 120, editable: false },
        { field: "gi_ymd", headerName: "출고일자", minWidth: 110, editable: false },
        { field: "gi_hms", headerName: "출고시간", minWidth: 100, editable: false },
        { field: "ord_no", headerName: "오더번호", minWidth: 140, editable: false },
        { field: "car_no", headerName: "차량번호", minWidth: 120, editable: true },
        { field: "driver_nm", headerName: "기사명", minWidth: 110, editable: false },
        { field: "driver_telno", headerName: "기사전화번호", minWidth: 150, editable: true },
        { field: "transco_cd", headerName: "운송사", minWidth: 110, editable: false },
        { field: "rmk", headerName: "비고", minWidth: 200, editable: true }
      ]
    end

    def detail_columns
      [
        { field: "lineno", headerName: "라인번호", minWidth: 90, editable: false },
        { field: "item_cd", headerName: "아이템코드", minWidth: 130, editable: false },
        { field: "item_nm", headerName: "아이템명", minWidth: 200, editable: false },
        { field: "unit_cd", headerName: "단위", minWidth: 80, editable: false },
        { field: "gi_idct_qty", headerName: "출고지시물량", minWidth: 120, editable: false, type: "numericColumn" },
        { field: "gi_rslt_qty", headerName: "출고실적물량", minWidth: 120, editable: false, type: "numericColumn" },
        { field: "assign_qty", headerName: "할당물량", minWidth: 110, editable: false, type: "numericColumn" },
        { field: "pick_qty", headerName: "피킹물량", minWidth: 110, editable: false, type: "numericColumn" },
        {
          field: "gi_stat_cd", headerName: "출고상태", minWidth: 110, editable: false,
          cellRenderer: "commonCodeCellRenderer",
          cellRendererParams: { codeGroup: "155" }
        },
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
        { field: "rmk", headerName: "비고", minWidth: 200, editable: true }
      ]
    end

    def pick_columns
      [
        { field: "lineno", headerName: "라인번호", minWidth: 90, editable: false },
        { field: "pick_no", headerName: "피킹번호", minWidth: 140, editable: false },
        { field: "item_cd", headerName: "아이템코드", minWidth: 130, editable: false },
        { field: "item_nm", headerName: "아이템명", minWidth: 190, editable: false },
        { field: "unit_cd", headerName: "단위", minWidth: 80, editable: false },
        { field: "loc_cd", headerName: "로케이션", minWidth: 120, editable: false },
        { field: "stock_qty", headerName: "재고물량", minWidth: 110, editable: false, type: "numericColumn" },
        { field: "assign_qty", headerName: "할당물량", minWidth: 110, editable: true, type: "numericColumn" },
        { field: "pick_qty", headerName: "피킹물량", minWidth: 110, editable: true, type: "numericColumn" },
        {
          field: "pick_stat_cd", headerName: "상태", minWidth: 90, editable: false,
          cellRenderer: "commonCodeCellRenderer",
          cellRendererParams: { codeGroup: "155" }
        },
        { field: "pick_ymd", headerName: "피킹일자", minWidth: 110, editable: false },
        { field: "pick_hms", headerName: "피킹시간", minWidth: 100, editable: false },
        { field: "rmk", headerName: "비고", minWidth: 180, editable: true }
      ]
    end
end
