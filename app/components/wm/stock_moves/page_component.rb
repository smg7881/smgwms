class Wm::StockMoves::PageComponent < Wm::BasePageComponent
  private
    def collection_path(**) = helpers.wm_stock_moves_path(**)
    def member_path(_id, **) = helpers.wm_stock_moves_path(**)

    def move_url
      helpers.move_wm_stock_moves_path
    end

    def search_fields
      [
        {
          field: "workpl_nm",
          type: "popup",
          label: "작업장",
          popup_type: "workplace",
          code_field: "workpl_cd",
          placeholder: "작업장 선택",
          required: true
        },
        {
          field: "cust_nm",
          type: "popup",
          label: "고객",
          popup_type: "customer",
          code_field: "cust_cd",
          placeholder: "고객 선택"
        },
        {
          field: "item_nm",
          type: "popup",
          label: "아이템",
          popup_type: "item",
          code_field: "item_cd",
          placeholder: "아이템 선택"
        },
        {
          field: "area_nm",
          type: "popup",
          label: "영역",
          popup_type: "area",
          code_field: "area_cd",
          placeholder: "영역 선택",
          popup_params: [ "workpl_cd" ]
        },
        {
          field: "zone_nm",
          type: "popup",
          label: "적치구역",
          popup_type: "zone",
          code_field: "zone_cd",
          placeholder: "적치구역 선택",
          popup_params: [ "workpl_cd", "area_cd" ]
        },
        {
          field: "loc_nm",
          type: "popup",
          label: "로케이션",
          popup_type: "location",
          code_field: "loc_cd",
          placeholder: "로케이션 선택",
          popup_params: [ "workpl_cd", "area_cd", "zone_cd" ]
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
        { field: "cust_cd", headerName: "고객사코드", minWidth: 110, editable: false },
        { field: "cust_nm", headerName: "고객사", minWidth: 130, editable: false },
        { field: "area_cd", headerName: "영역", minWidth: 90, editable: false },
        { field: "zone_cd", headerName: "적치구역", minWidth: 100, editable: false },
        { field: "loc_cd", headerName: "로케이션", minWidth: 100, editable: false },
        { field: "item_cd", headerName: "아이템코드", minWidth: 120, editable: false },
        { field: "item_nm", headerName: "아이템명", minWidth: 140, editable: false },
        { field: "stock_attr_no", headerName: "재고속성번호", minWidth: 120, editable: false },
        { field: "stock_attr_col01", headerName: "재고속성01", minWidth: 110, editable: false },
        { field: "stock_attr_col02", headerName: "재고속성02", minWidth: 110, editable: false },
        { field: "stock_attr_col03", headerName: "재고속성03", minWidth: 110, editable: false },
        { field: "stock_attr_col04", headerName: "재고속성04", minWidth: 110, editable: false },
        { field: "stock_attr_col05", headerName: "재고속성05", minWidth: 110, editable: false },
        { field: "stock_attr_col06", headerName: "재고속성06", minWidth: 110, editable: false },
        { field: "stock_attr_col07", headerName: "재고속성07", minWidth: 110, editable: false },
        { field: "stock_attr_col08", headerName: "재고속성08", minWidth: 110, editable: false },
        { field: "stock_attr_col09", headerName: "재고속성09", minWidth: 110, editable: false },
        { field: "stock_attr_col10", headerName: "재고속성10", minWidth: 110, editable: false },
        { field: "basis_unit_cd", headerName: "단위코드", minWidth: 90, editable: false },
        { field: "qty", headerName: "재고물량", minWidth: 100, editable: false, type: "numericColumn" },
        { field: "assign_qty", headerName: "할당물량", minWidth: 100, editable: false, type: "numericColumn" },
        { field: "pick_qty", headerName: "피킹물량", minWidth: 100, editable: false, type: "numericColumn" },
        { field: "move_poss_qty", headerName: "이동가능물량", minWidth: 120, editable: false, type: "numericColumn" },
        { field: "to_loc_cd", headerName: "TO 로케이션", minWidth: 120, editable: true },
        { field: "move_qty", headerName: "이동수량", minWidth: 100, editable: true, cellEditor: "agNumberCellEditor", type: "numericColumn" }
      ]
    end
end
