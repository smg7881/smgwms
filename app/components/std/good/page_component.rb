class Std::Good::PageComponent < Std::BasePageComponent
  private
    def collection_path(**) = helpers.std_goods_path(**)
    def member_path(_id, **) = helpers.std_goods_path(**)

    def batch_save_url
      helpers.batch_save_std_goods_path
    end

    def search_fields
      [
        { field: "goods_cd", type: "input", label: "Goods Code", placeholder: "Search code" },
        { field: "goods_nm", type: "input", label: "Goods Name", placeholder: "Search goods name" },
        {
          field: "use_yn_cd",
          type: "select",
          label: "Use Y/N",
          options: common_code_options("CMM_USE_YN", include_all: true),
          include_blank: false
        }
      ]
    end

    def columns
      [
        {
          field: "__row_status",
          headerName: "Status",
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
        { field: "goods_cd", headerName: "Goods Code", minWidth: 110, editable: true },
        { field: "goods_nm", headerName: "Goods Name", minWidth: 160, editable: true },
        {
          field: "hatae_cd",
          headerName: "Hatae",
          minWidth: 110,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("STD_HATAE") }
        },
        {
          field: "item_grp_cd",
          headerName: "Item Group",
          minWidth: 110,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("STD_ITEM_GRP") }
        },
        {
          field: "item_cd",
          headerName: "Item",
          minWidth: 110,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("STD_ITEM") }
        },
        {
          field: "hwajong_cd",
          headerName: "Cargo Type",
          minWidth: 110,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("STD_HWAJONG") }
        },
        {
          field: "hwajong_grp_cd",
          headerName: "Cargo Group",
          minWidth: 110,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("STD_HWAJONG_GRP") }
        },
        { field: "rmk_cd", headerName: "Remark", minWidth: 200, editable: true },
        {
          field: "use_yn_cd",
          headerName: "Use Y/N",
          maxWidth: 90,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("CMM_USE_YN") },
          cellRenderer: "codeUseYnCellRenderer"
        },
        { field: "update_by", headerName: "Updated By", minWidth: 100, editable: false },
        { field: "update_time", headerName: "Updated At", minWidth: 160, formatter: "datetime", editable: false }
      ]
    end
end
