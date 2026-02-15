class System::Menus::FormModalComponent < ApplicationComponent
  private
    def fields
      [
        { field: "menu_cd", type: "input", label: "Menu Code", required: true, maxlength: 20, target: "fieldMenuCd" },
        { field: "menu_nm", type: "input", label: "Menu Name", required: true, maxlength: 100, target: "fieldMenuNm" },
        { field: "parent_cd", type: "input", label: "Parent Menu Code", maxlength: 20, readonly: true, target: "fieldParentCd" },
        { field: "menu_url", type: "input", label: "URL", maxlength: 200, target: "fieldMenuUrl" },
        { field: "menu_icon", type: "input", label: "Icon (lucide)", maxlength: 50, target: "fieldMenuIcon" },
        { field: "sort_order", type: "number", label: "Sort Order", value: 0, target: "fieldSortOrder" },
        { field: "menu_level", type: "number", label: "Level", readonly: true, target: "fieldMenuLevel" },
        {
          field: "menu_type",
          type: "select",
          label: "Type",
          include_blank: false,
          options: [ { label: "FOLDER", value: "FOLDER" }, { label: "MENU", value: "MENU" } ],
          target: "fieldMenuType"
        },
        {
          field: "use_yn",
          type: "select",
          label: "Use Y/N",
          include_blank: false,
          options: [ { label: "Y", value: "Y" }, { label: "N", value: "N" } ],
          target: "fieldUseYn"
        },
        { field: "tab_id", type: "input", label: "Tab ID", maxlength: 50, target: "fieldTabId" }
      ]
    end
end