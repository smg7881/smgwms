class Om::InternalOrder::PageComponent < Om::BasePageComponent
  def initialize(query_params:, search_form:)
    super(query_params: query_params)
    @search_form = search_form
  end

  private
    attr_reader :search_form

    def collection_path(**) = helpers.om_internal_orders_path(**)
    def member_path(id, **) = helpers.om_internal_order_path(id, **)

    def search_url
      helpers.om_internal_orders_path(format: :json)
    end

    def cancel_url
      helpers.cancel_om_internal_order_path(":id")
    end

    def ord_stat_options
      common_code_options("OM_ORD_STAT")
    end

    def loc_type_options
      common_code_options("OM_LOC_TYPE")
    end

    def qty_unit_options
      common_code_values("OM_QTY_UNIT")
    end

    def wgt_unit_options
      common_code_values("OM_WGT_UNIT")
    end

    def vol_unit_options
      common_code_values("OM_VOL_UNIT")
    end

    def item_columns
      [
        {
          field: "seq_no",
          headerName: "순번",
          width: 80,
          editable: false,
          cellStyle: { textAlign: "center" }
        },
        {
          field: "item_cd",
          headerName: "아이템코드",
          minWidth: 130,
          editable: true
        },
        {
          field: "item_nm",
          headerName: "아이템명",
          minWidth: 180,
          editable: true
        },
        {
          field: "basis_unit_cd",
          headerName: "기본단위",
          width: 100,
          editable: true
        },
        {
          field: "ord_qty",
          headerName: "수량",
          width: 100,
          editable: true,
          cellStyle: { textAlign: "right" },
          type: "numericColumn"
        },
        {
          field: "qty_unit_cd",
          headerName: "수량단위",
          width: 100,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: qty_unit_options }
        },
        {
          field: "ord_wgt",
          headerName: "중량",
          width: 100,
          editable: true,
          cellStyle: { textAlign: "right" },
          type: "numericColumn"
        },
        {
          field: "wgt_unit_cd",
          headerName: "중량단위",
          width: 100,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: wgt_unit_options }
        },
        {
          field: "ord_vol",
          headerName: "부피",
          width: 100,
          editable: true,
          cellStyle: { textAlign: "right" },
          type: "numericColumn"
        },
        {
          field: "vol_unit_cd",
          headerName: "부피단위",
          width: 100,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: vol_unit_options }
        }
      ]
    end

    def search_fields
      [
        {
          field: "search_ord_no",
          type: "text",
          label: "오더번호",
          placeholder: "오더번호 입력",
          data: {
            om_internal_order_target: "searchOrdNo",
            action: "keydown.enter->om-internal-order#search"
          }
        }
      ]
    end
end
