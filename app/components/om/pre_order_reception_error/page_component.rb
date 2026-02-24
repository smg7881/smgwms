class Om::PreOrderReceptionError::PageComponent < Om::BasePageComponent
  def initialize(query_params:, search_form:)
    super(query_params: query_params)
    @search_form = search_form
  end

  private
    attr_reader :search_form

    def collection_path(**) = helpers.om_pre_order_reception_errors_path(**)
    def member_path(_id, **) = helpers.om_pre_order_reception_errors_path(**)

    def items_url
      helpers.items_om_pre_order_reception_errors_path
    end

    def reprocess_url
      helpers.reprocess_om_pre_order_reception_errors_path
    end

    def download_template_url
      helpers.download_template_om_pre_order_reception_errors_path
    end

    def upload_template_url
      helpers.upload_template_om_pre_order_reception_errors_path
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
          field: "resolved_yn",
          type: "select",
          label: "처리여부",
          options: resolved_options,
          include_blank: false
        },
        {
          field: "recp_start_ymd",
          type: "date_picker",
          label: "접수 시작일",
          required: true
        },
        {
          field: "recp_end_ymd",
          type: "date_picker",
          label: "접수 종료일",
          required: true
        }
      ]
    end

    def master_columns
      [
        { field: "id", headerName: "ID", hide: true, editable: false },
        { field: "recp_seq", headerName: "접수순번", minWidth: 100, maxWidth: 110, editable: false },
        { field: "sctn_cd", headerName: "구분", minWidth: 110, editable: false },
        { field: "msg_cd", headerName: "메시지코드", minWidth: 120, editable: false },
        { field: "err_msg", headerName: "메시지", minWidth: 240, editable: false },
        { field: "cust_ord_no", headerName: "고객오더번호", minWidth: 150, editable: false },
        { field: "cust_cd", headerName: "고객코드", minWidth: 110, editable: false },
        { field: "cust_nm", headerName: "고객명", minWidth: 160, editable: false },
        { field: "recp_ymd", headerName: "접수일자", minWidth: 120, editable: false },
        { field: "item_cd", headerName: "품목코드", minWidth: 120, editable: false },
        { field: "qty", headerName: "수량", minWidth: 90, editable: false, cellClass: "text-right" },
        { field: "wgt", headerName: "중량", minWidth: 90, editable: false, cellClass: "text-right" },
        { field: "vol", headerName: "부피", minWidth: 90, editable: false, cellClass: "text-right" },
        {
          field: "resolved_yn",
          headerName: "처리여부",
          minWidth: 100,
          editable: false,
          cellRenderer: "codeUseYnCellRenderer"
        },
        { field: "ord_no", headerName: "생성오더번호", minWidth: 150, editable: false },
        { field: "line_no", headerName: "라인번호", hide: true, editable: false },
        { field: "upload_batch_no", headerName: "업로드배치번호", hide: true, editable: false }
      ]
    end

    def detail_columns
      [
        { field: "line_no", headerName: "라인번호", minWidth: 100, maxWidth: 110, editable: false },
        { field: "msg", headerName: "메시지", minWidth: 260, editable: false },
        { field: "item_cd", headerName: "품목코드", minWidth: 120, editable: false },
        { field: "qty", headerName: "수량", minWidth: 100, editable: false, cellClass: "text-right" },
        { field: "qty_unit_cd", headerName: "수량단위", minWidth: 110, editable: false },
        { field: "wgt", headerName: "중량", minWidth: 100, editable: false, cellClass: "text-right" },
        { field: "wgt_unit_cd", headerName: "중량단위", minWidth: 110, editable: false },
        { field: "vol", headerName: "부피", minWidth: 100, editable: false, cellClass: "text-right" },
        { field: "vol_unit_cd", headerName: "부피단위", minWidth: 110, editable: false }
      ]
    end

    def resolved_options
      [
        { label: "미처리", value: "N" },
        { label: "처리완료", value: "Y" }
      ]
    end
end
