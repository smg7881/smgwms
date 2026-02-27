class Wm::CustStockAttr::PageComponent < System::BasePageComponent
  private
    def collection_path(**) = helpers.wm_cust_stock_attrs_path(**)

    def batch_save_url
      helpers.batch_save_wm_cust_stock_attrs_path
    end

    def search_fields
      [
        { field: "cust_cd", type: "popup", label: "고객", popup_type: "customer_group_customer", code_field: "cust_cd", name_field: "cust_nm", placeholder: "고객 검색.." },
        {
          field: "inout_sctn",
          type: "select",
          label: "입출고구분",
          options: common_code_options("82", include_all: true),
          include_blank: false
        }
      ]
    end

    def columns
      [
        {
          field: "__row_status",
          headerName: "상태",
          width: 68, minWidth: 68, maxWidth: 68,
          editable: false, sortable: false, filter: false, resizable: false,
          cellStyle: { textAlign: "center" },
          cellRenderer: "rowStatusCellRenderer"
        },
        { field: "cust_cd", headerName: "고객코드(숨김)", hide: true },
        { field: "cust_nm", headerName: "고객", minWidth: 150, editable: false },
        {
          field: "inout_sctn",
          headerName: "입출고구분",
          minWidth: 130,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("82") },
          cellRenderer: "createStatusBadge", cellRendererParams: { trueLabel: "Y" } # 공통코드 렌더러
        },
        {
          field: "stock_attr_sctn",
          headerName: "재고속성구분",
          minWidth: 140,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("101") },
          cellRenderer: "createStatusBadge", cellRendererParams: { trueLabel: "Y" } # 공통코드 렌더러
        },
        { field: "attr_desc", headerName: "속성설명", minWidth: 200, editable: true },
        { field: "rel_tbl", headerName: "관련테이블", minWidth: 150, editable: true },
        { field: "rel_col", headerName: "관련칼럼", minWidth: 150, editable: true },
        {
          field: "use_yn",
          headerName: "사용여부",
          maxWidth: 110,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("06") },
          cellRenderer: "createStatusBadge", cellRendererParams: { trueLabel: "Y" }
        }
      ]
    end
end
