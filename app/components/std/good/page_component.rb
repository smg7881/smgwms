class Std::Good::PageComponent < Std::BasePageComponent
  private
    def collection_path(**) = helpers.std_goods_path(**)
    def member_path(_id, **) = helpers.std_goods_path(**)

    def batch_save_url
      helpers.batch_save_std_goods_path
    end

    def search_fields
      [
        { field: "goods_cd", type: "input", label: "품명코드", placeholder: "코드 검색" },
        { field: "goods_nm", type: "input", label: "품명", placeholder: "품명 검색" },
        {
          field: "use_yn_cd",
          type: "select",
          label: "사용여부",
          options: common_code_options("CMM_USE_YN", include_all: true, all_label: "전체"),
          include_blank: false
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
        { field: "goods_cd", headerName: "품명코드", minWidth: 110, editable: true },
        { field: "goods_nm", headerName: "품명", minWidth: 160, editable: true },
        {
          field: "hatae_cd",
          headerName: "하태코드",
          minWidth: 110,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("STD_HATAE") }
        },
        {
          field: "item_grp_cd",
          headerName: "품목그룹",
          minWidth: 110,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("STD_ITEM_GRP") }
        },
        {
          field: "item_cd",
          headerName: "품목",
          minWidth: 110,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("STD_ITEM") }
        },
        {
          field: "hwajong_cd",
          headerName: "화종",
          minWidth: 110,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("STD_HWAJONG") }
        },
        {
          field: "hwajong_grp_cd",
          headerName: "화종그룹",
          minWidth: 110,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("STD_HWAJONG_GRP") }
        },
        { field: "rmk_cd", headerName: "비고", minWidth: 200, editable: true },
        {
          field: "use_yn_cd",
          headerName: "사용여부",
          maxWidth: 90,
          editable: true,
          cellEditor: "agSelectCellEditor",
          cellEditorParams: { values: common_code_values("CMM_USE_YN") },
          cellRenderer: "codeUseYnCellRenderer"
        },
        { field: "update_by", headerName: "수정자", minWidth: 100, editable: false },
        { field: "update_time", headerName: "수정일시", minWidth: 160, formatter: "datetime", editable: false }
      ]
    end
end
