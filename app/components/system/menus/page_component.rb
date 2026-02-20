class System::Menus::PageComponent < System::BasePageComponent
  private
    def collection_path(**) = helpers.system_menus_path(**)
    def member_path(id, **) = helpers.system_menu_path(id, **)

    def search_fields
      [
        { field: "menu_cd", type: "input", label: "메뉴코드", placeholder: "메뉴코드 검색..." },
        { field: "menu_nm", type: "input", label: "메뉴명", placeholder: "메뉴명 검색..." },
        {
          field: "use_yn",
          type: "select",
          label: "사용여부",
          options: common_code_options("CMM_USE_YN", include_all: true),
          include_blank: false
        }
      ]
    end

    def columns
      [
        { field: "menu_nm", headerName: "메뉴명", minWidth: 250, cellRenderer: "treeMenuCellRenderer" },
        { field: "menu_cd", headerName: "메뉴코드", minWidth: 120 },
        { field: "menu_url", headerName: "URL", minWidth: 150 },
        { field: "sort_order", headerName: "정렬", maxWidth: 80 },
        { field: "menu_type", headerName: "타입", maxWidth: 100 },
        { field: "use_yn", headerName: "사용", maxWidth: 70 },
        { field: "tab_id", headerName: "탭ID", minWidth: 120 },
        { field: "actions", headerName: "작업", minWidth: 130, maxWidth: 130, filter: false, sortable: false, cellRenderer: "actionCellRenderer" }
      ]
    end

    def form_fields
      [
        { field: "menu_cd", type: "input", label: "메뉴코드", required: true, maxlength: 20, target: "fieldMenuCd" },
        { field: "menu_nm", type: "input", label: "메뉴명", required: true, maxlength: 100, target: "fieldMenuNm" },
        { field: "parent_cd", type: "input", label: "상위메뉴코드", maxlength: 20, readonly: true, target: "fieldParentCd" },
        { field: "menu_url", type: "input", label: "URL", maxlength: 200, target: "fieldMenuUrl" },
        { field: "menu_icon", type: "input", label: "아이콘 (Lucide)", maxlength: 50, target: "fieldMenuIcon" },
        { field: "sort_order", type: "number", label: "정렬순서", value: 0, target: "fieldSortOrder" },
        { field: "menu_level", type: "number", label: "레벨", readonly: true, target: "fieldMenuLevel" },
        {
          field: "menu_type",
          type: "select",
          label: "타입",
          include_blank: false,
          options: common_code_options("MENU_TYPE"),
          target: "fieldMenuType"
        },
        {
          field: "use_yn",
          type: "select",
          label: "사용여부",
          include_blank: false,
          options: common_code_options("CMM_USE_YN"),
          target: "fieldUseYn"
        },
        { field: "tab_id", type: "input", label: "탭 ID", maxlength: 50, target: "fieldTabId" }
      ]
    end
end
