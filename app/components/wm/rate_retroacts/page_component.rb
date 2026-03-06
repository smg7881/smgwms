class Wm::RateRetroacts::PageComponent < Wm::BasePageComponent
  def initialize(query_params:, selected_fee_rt_no: nil)
    super(query_params: query_params)
    @selected_fee_rt_no = selected_fee_rt_no.to_s.strip.presence
  end

  private
    attr_reader :selected_fee_rt_no

    def collection_path(**options) = helpers.wm_rate_retroacts_path(**options)
    def member_path(id, **) = helpers.wm_rate_retroact_path(id, **)
    def detail_collection_path(id, **) = helpers.wm_rate_retroact_details_path(id, **)

    def detail_grid_url
      if selected_fee_rt_no.present?
        detail_collection_path(selected_fee_rt_no, format: :json)
      else
        nil
      end
    end

    def apply_retro_rates_url
      helpers.apply_retro_rates_wm_rate_retroacts_path
    end

    def process_retroacts_url
      helpers.process_retroacts_wm_rate_retroacts_path
    end

    def master_batch_save_url
      helpers.batch_save_wm_rate_retroacts_path
    end

    def detail_batch_save_url_template
      "/wm/rate_retroacts/:id/details/batch_save"
    end

    def selected_master_label
      if selected_fee_rt_no.present?
        "선택 요율: #{selected_fee_rt_no}"
      else
        "요율을 먼저 선택하세요."
      end
    end

    def selected_retro_rate_label
      "소급요율을 선택하세요."
    end

    def search_fields
      [
        {
          field: "work_pl_nm",
          type: "popup",
          label: "작업장",
          popup_type: "workplace",
          code_field: "work_pl_cd",
          placeholder: "작업장명 검색"
        },
        {
          field: "sell_buy_sctn_cd",
          type: "select",
          label: "매출입구분",
          options: common_code_options("80", include_all: false),
          include_blank: false
        },
        {
          field: "bzac_nm",
          type: "popup",
          label: "거래처",
          popup_type: "client",
          code_field: "bzac_cd",
          placeholder: "거래처명 검색"
        },
        {
          field: "sell_buy_attr_nm",
          type: "popup",
          label: "매출입항목",
          popup_type: "sellbuy_attr",
          code_field: "sell_buy_attr_cd",
          placeholder: "매출입항목명 검색"
        },
        {
          field: "aply_date",
          type: "date_range",
          label: "적용일자"
        },
        {
          field: "rslt_std_date",
          type: "date_range",
          label: "실적기준일자"
        },
        {
          field: "use_yn",
          type: "select",
          label: "사용여부",
          options: common_code_options("06", include_all: false),
          include_blank: false
        }
      ]
    end

    def master_columns
      [
        row_status_column,
        { field: "wrhs_exca_fee_rt_no", headerName: "요율번호", minWidth: 170, editable: false },
        { field: "sell_buy_attr_cd", headerName: "매출입항목코드", minWidth: 140, editable: false },
        { field: "sell_buy_attr_nm", headerName: "매출입항목명", minWidth: 180, editable: false },
        { field: "sell_buy_unit", headerName: "매출입단위", minWidth: 120, editable: false },
        { field: "aply_feert", headerName: "적용요율", minWidth: 110, editable: false, type: "numericColumn" },
        { field: "aply_strt_ymd", headerName: "적용시작일자", minWidth: 140, editable: false },
        { field: "aply_end_ymd", headerName: "적용종료일자", minWidth: 140, editable: false },
        { field: "rtac_feert", headerName: "소급요율", minWidth: 110, editable: false, type: "numericColumn" }
      ]
    end

    def detail_columns
      [
        row_status_column,
        {
          field: "selected",
          headerName: "선택",
          minWidth: 80,
          maxWidth: 80,
          editable: false,
          checkboxSelection: true,
          headerCheckboxSelection: true,
          cellStyle: { textAlign: "center" }
        },
        { field: "rslt_std_ymd", headerName: "실적기준일자", minWidth: 130, editable: false },
        { field: "rslt_rcgt_sctn", headerName: "실적인식구분", minWidth: 120, editable: false },
        { field: "op_rslt_mngt_no", headerName: "운영실적관리번호", minWidth: 170, editable: false },
        { field: "lineno", headerName: "라인번호", minWidth: 90, editable: false },
        { field: "rslt_qty", headerName: "실적물량", minWidth: 100, editable: false, type: "numericColumn" },
        { field: "aply_uprice", headerName: "적용단가", minWidth: 100, editable: false, type: "numericColumn" },
        { field: "rslt_amt", headerName: "실적금액", minWidth: 110, editable: false, type: "numericColumn" },
        {
          field: "cur_cd",
          headerName: "통화코드",
          minWidth: 100,
          editable: false,
          refData: common_code_map("27")
        },
        { field: "rtac_uprice", headerName: "소급단가", minWidth: 100, editable: false, type: "numericColumn" },
        { field: "rtac_amt", headerName: "소급금액", minWidth: 110, editable: false, type: "numericColumn" },
        { field: "uprice_diff", headerName: "단가차이", minWidth: 100, editable: false, type: "numericColumn" },
        { field: "amt_diff", headerName: "금액차이", minWidth: 110, editable: false, type: "numericColumn" },
        { field: "prcs_sctn_cd", headerName: "처리구분", minWidth: 90, editable: false }
      ]
    end

    def row_status_column
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
      }
    end
end
