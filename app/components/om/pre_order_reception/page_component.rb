class Om::PreOrderReception::PageComponent < Om::BasePageComponent
  def initialize(query_params:, search_form:)
    super(query_params: query_params)
    @search_form = search_form
  end

  private
    attr_reader :search_form

    def collection_path(**) = helpers.om_pre_order_receptions_path(**)
    def member_path(_id, **) = helpers.om_pre_order_receptions_path(**)

    def create_order_url
      helpers.create_orders_om_pre_order_receptions_path
    end

    def items_url
      helpers.items_om_pre_order_receptions_path
    end

    def search_fields
      [
        {
          field: "cust_nm",
          type: "popup",
          label: "고객",
          popup_type: "client",
          code_field: "cust_cd",
          value: search_form.cust_nm,
          placeholder: "고객 선택",
          display_width: "220px",
          code_width: "120px"
        },
        {
          field: "cust_ord_no",
          type: "input",
          label: "고객오더번호",
          placeholder: "고객오더번호 입력"
        },
        {
          field: "bef_ord_no",
          type: "input",
          label: "사전오더번호",
          placeholder: "사전오더번호 입력"
        },
        {
          field: "status_cd",
          type: "select",
          label: "상태",
          options: status_options,
          include_blank: false
        },
        {
          field: "recp_start_ymd",
          type: "date_picker",
          label: "접수시작일",
          required: true
        },
        {
          field: "recp_end_ymd",
          type: "date_picker",
          label: "접수종료일",
          required: true
        }
      ]
    end

    def master_columns
      [
        { field: "recp_seq", headerName: "접수순번", minWidth: 90, maxWidth: 100, editable: false },
        { field: "bef_ord_no", headerName: "사전오더번호", minWidth: 140, editable: false },
        { field: "status_cd", headerName: "상태", minWidth: 120, editable: false },
        { field: "cust_ord_no", headerName: "고객오더번호", minWidth: 140, editable: false },
        { field: "cust_cd", headerName: "고객코드", minWidth: 120, editable: false },
        { field: "cust_nm", headerName: "고객명", minWidth: 180, editable: false },
        { field: "item_cd", headerName: "품목코드", minWidth: 120, editable: false },
        { field: "item_nm", headerName: "품목명", minWidth: 180, editable: false },
        { field: "qty", headerName: "수량", minWidth: 100, editable: false, cellClass: "text-right" },
        { field: "wgt", headerName: "중량", minWidth: 100, editable: false, cellClass: "text-right" },
        { field: "vol", headerName: "부피", minWidth: 100, editable: false, cellClass: "text-right" },
        { field: "recp_ymd", headerName: "접수일자", minWidth: 120, editable: false },
        { field: "ord_no", headerName: "생성오더번호", minWidth: 140, editable: false },
        { field: "update_time", headerName: "수정일시", minWidth: 160, formatter: "datetime", editable: false }
      ]
    end

    def detail_columns
      [
        { field: "line_no", headerName: "라인번호", minWidth: 90, maxWidth: 100, editable: false },
        { field: "item_cd", headerName: "품목코드", minWidth: 120, editable: false },
        { field: "item_nm", headerName: "품목명", minWidth: 180, editable: false },
        { field: "qty", headerName: "수량", minWidth: 100, editable: false, cellClass: "text-right" },
        { field: "qty_unit_cd", headerName: "수량단위", minWidth: 100, editable: false },
        { field: "wgt", headerName: "중량", minWidth: 100, editable: false, cellClass: "text-right" },
        { field: "wgt_unit_cd", headerName: "중량단위", minWidth: 100, editable: false },
        { field: "vol", headerName: "부피", minWidth: 100, editable: false, cellClass: "text-right" },
        { field: "vol_unit_cd", headerName: "부피단위", minWidth: 100, editable: false }
      ]
    end

    def status_options
      [
        { label: "전체", value: "" },
        { label: "접수", value: OmPreOrderReception::STATUS_RECEIVED },
        { label: "오더생성", value: OmPreOrderReception::STATUS_ORDER_CREATED }
      ]
    end
end
