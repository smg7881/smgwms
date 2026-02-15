class System::Menus::PageComponent < ApplicationComponent
  def initialize(query_params:)
    @query_params = query_params
  end

  private
    attr_reader :query_params

    def create_url
      helpers.system_menus_path
    end

    def update_url
      helpers.system_menu_path(":id")
    end

    def delete_url
      helpers.system_menu_path(":id")
    end

    def grid_url
      helpers.system_menus_path(format: :json, q: query_params["q"])
    end

    def search_fields
      [
        { field: "menu_cd", type: "input", label: "메뉴코드", placeholder: "메뉴코드 검색..." },
        { field: "menu_nm", type: "input", label: "메뉴명", placeholder: "메뉴명 검색..." },
        {
          field: "use_yn",
          type: "select",
          label: "사용여부",
          options: [
            { label: "전체", value: "" },
            { label: "사용", value: "Y" },
            { label: "미사용", value: "N" }
          ],
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
end
