class Om::OrderManualCompletion::PageComponent < Om::BasePageComponent
  def initialize(query_params:, search_form:)
    super(query_params: query_params)
    @search_form = search_form
  end

  private
    attr_reader :search_form

    def collection_path(**) = helpers.om_order_manual_completions_path(**)
    def member_path(id, **) = helpers.om_order_manual_completion_path(id, **)

    def complete_path
      helpers.complete_om_order_manual_completions_path
    end

    def details_path_template
      helpers.details_om_order_manual_completion_path("__ORD_NO__")
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
          field: "date_type",
          type: "select",
          label: "일자구분",
          options: [
            [ "오더생성일자", "create_time" ],
            [ "납기요청일자", "aptd_req_ymd" ]
          ],
          include_blank: false,
          required: true
        },
        {
          field: "start_date",
          type: "date_picker",
          label: "시작일자",
          required: true
        },
        {
          field: "end_date",
          type: "date_picker",
          label: "종료일자",
          required: true
        },
        {
          field: "ord_no",
          type: "input",
          label: "오더번호",
          placeholder: "오더번호 입력"
        }
      ]
    end

    def master_columns
      [
        {
          field: "ord_stat_nm",
          headerName: "오더상태",
          minWidth: 110,
          editable: false
        },
        {
          field: "ord_no",
          headerName: "오더번호",
          minWidth: 150,
          editable: false
        },
        {
          field: "ord_type_nm",
          headerName: "오더유형",
          minWidth: 140,
          editable: false
        },
        {
          field: "create_time",
          headerName: "오더생성일시",
          minWidth: 170,
          editable: false
        },
        {
          field: "aptd_req_ymd",
          headerName: "고객납기요청일자",
          minWidth: 140,
          editable: false
        },
        {
          field: "dpt_ar_nm",
          headerName: "출발지명",
          minWidth: 150,
          editable: false
        },
        {
          field: "arv_ar_nm",
          headerName: "도착지명",
          minWidth: 150,
          editable: false
        }
      ]
    end

    def detail_columns
      [
        {
          field: "seq",
          headerName: "순번",
          width: 80,
          editable: false,
          cellStyle: { textAlign: "center" }
        },
        {
          field: "div_dgr_cnt",
          headerName: "분배차수",
          width: 95,
          editable: false,
          cellStyle: { textAlign: "right" }
        },
        {
          field: "item_cd",
          headerName: "아이템코드",
          minWidth: 140,
          editable: false
        },
        {
          field: "item_nm",
          headerName: "아이템명",
          minWidth: 170,
          editable: false
        },
        {
          field: "work_stat",
          headerName: "작업상태",
          minWidth: 100,
          editable: false
        },
        {
          field: "ord_qty",
          headerName: "오더수량",
          width: 105,
          editable: false,
          cellStyle: { textAlign: "right" }
        },
        {
          field: "ord_wgt",
          headerName: "오더중량",
          width: 105,
          editable: false,
          cellStyle: { textAlign: "right" }
        },
        {
          field: "ord_vol",
          headerName: "오더부피",
          width: 105,
          editable: false,
          cellStyle: { textAlign: "right" }
        },
        {
          field: "rslt_qty",
          headerName: "실적수량",
          width: 105,
          editable: false,
          cellStyle: { textAlign: "right" }
        },
        {
          field: "rslt_wgt",
          headerName: "실적중량",
          width: 105,
          editable: false,
          cellStyle: { textAlign: "right" }
        },
        {
          field: "rslt_vol",
          headerName: "실적부피",
          width: 105,
          editable: false,
          cellStyle: { textAlign: "right" }
        },
        {
          field: "rem_qty",
          headerName: "잔여수량",
          width: 105,
          editable: false,
          cellStyle: { textAlign: "right", color: "#dc2626" }
        },
        {
          field: "rem_wgt",
          headerName: "잔여중량",
          width: 105,
          editable: false,
          cellStyle: { textAlign: "right", color: "#dc2626" }
        },
        {
          field: "rem_vol",
          headerName: "잔여부피",
          width: 105,
          editable: false,
          cellStyle: { textAlign: "right", color: "#dc2626" }
        }
      ]
    end
end
