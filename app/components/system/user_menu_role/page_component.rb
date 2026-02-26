class System::UserMenuRole::PageComponent < System::BasePageComponent
  private
    def collection_path(**) = helpers.system_user_menu_role_index_path(**)
    def member_path(_id, **) = helpers.system_user_menu_role_index_path(**)

    def users_url
      helpers.users_system_user_menu_role_index_path
    end

    def users_grid_url
      q_params = query_params["q"]
      q_params = q_params.to_unsafe_h if q_params.respond_to?(:to_unsafe_h)
      helpers.users_system_user_menu_role_index_path(format: :json, q: q_params)
    end

    def roles_by_user_url
      helpers.roles_by_user_system_user_menu_role_index_path
    end

    def menus_by_user_role_url
      helpers.menus_by_user_role_system_user_menu_role_index_path
    end

    def search_fields
      [
        { field: "user_nm", type: "input", label: "사용자명", placeholder: "사용자명 검색.." },
        { field: "dept_nm", type: "input", label: "부서명", placeholder: "부서명 검색.." }
      ]
    end

    def user_columns
      [
        { field: "user_id_code", headerName: "사번", minWidth: 120 },
        { field: "user_nm", headerName: "사용자명", minWidth: 120 },
        { field: "dept_nm", headerName: "부서명", minWidth: 130 },
        { field: "role_cd", headerName: "역할코드", minWidth: 110 }
      ]
    end

    def role_columns
      [
        { field: "role_cd", headerName: "역할코드", minWidth: 120 },
        { field: "role_nm", headerName: "역할명", minWidth: 120 },
        { field: "description", headerName: "설명", minWidth: 180 }
      ]
    end

    def menu_columns
      [
        { field: "menu_cd", headerName: "메뉴코드", minWidth: 120 },
        { field: "menu_nm", headerName: "메뉴명", minWidth: 140 },
        { field: "menu_url", headerName: "URL", minWidth: 180 },
        { field: "menu_type", headerName: "타입", minWidth: 90 },
        { field: "menu_level", headerName: "레벨", minWidth: 80 }
      ]
    end
end
