require "test_helper"

class System::MenusControllerTest < ActionDispatch::IntegrationTest
  setup do
    post session_path, params: { email_address: "admin@example.com", password: "password" }
  end

  test "index responds to html" do
    get system_menus_url
    assert_response :success
  end

  test "index responds to json" do
    get system_menus_url(format: :json)
    assert_response :success

    json = JSON.parse(response.body)
    assert_operator json.length, :>=, 1
  end

  test "index json includes ancestor menus when filtered" do
    AdmMenu.create!(
      menu_cd: "SEARCH_ROOT",
      menu_nm: "Search Root",
      parent_cd: nil,
      menu_url: nil,
      menu_icon: nil,
      sort_order: 90,
      menu_level: 1,
      menu_type: "FOLDER",
      use_yn: "Y",
      tab_id: nil
    )
    AdmMenu.create!(
      menu_cd: "SEARCH_PARENT",
      menu_nm: "Search Parent",
      parent_cd: "SEARCH_ROOT",
      menu_url: nil,
      menu_icon: nil,
      sort_order: 1,
      menu_level: 2,
      menu_type: "FOLDER",
      use_yn: "Y",
      tab_id: nil
    )
    AdmMenu.create!(
      menu_cd: "SEARCH_LEAF",
      menu_nm: "Search Leaf",
      parent_cd: "SEARCH_PARENT",
      menu_url: "/search/leaf",
      menu_icon: nil,
      sort_order: 1,
      menu_level: 3,
      menu_type: "MENU",
      use_yn: "Y",
      tab_id: "search-leaf"
    )

    get system_menus_url(format: :json), params: { q: { menu_cd: "SEARCH_LEAF" } }
    assert_response :success

    json = JSON.parse(response.body)
    menu_codes = json.map { |menu| menu["menu_cd"] }
    assert_equal [ "SEARCH_ROOT", "SEARCH_PARENT", "SEARCH_LEAF" ], menu_codes
  end

  test "creates menu" do
    assert_difference("AdmMenu.count", 1) do
      post system_menus_url, params: {
        menu: {
          menu_cd: "TEST_MENU",
          menu_nm: "테스트 메뉴",
          parent_cd: "MAIN",
          menu_url: "/test",
          sort_order: 10,
          menu_level: 2,
          menu_type: "MENU",
          use_yn: "Y"
        }
      }, as: :json
    end
    assert_response :success
  end

  test "rejects delete when children exist" do
    parent = AdmMenu.create!(
      menu_cd: "PARENT_MENU",
      menu_nm: "Parent",
      parent_cd: nil,
      menu_url: nil,
      menu_icon: nil,
      sort_order: 100,
      menu_level: 1,
      menu_type: "FOLDER",
      use_yn: "Y",
      tab_id: nil
    )

    AdmMenu.create!(
      menu_cd: "CHILD_MENU",
      menu_nm: "Child",
      parent_cd: parent.menu_cd,
      menu_url: "/child",
      menu_icon: nil,
      sort_order: 1,
      menu_level: 2,
      menu_type: "MENU",
      use_yn: "Y",
      tab_id: "child-menu"
    )

    delete system_menu_url(parent), as: :json
    assert_response :unprocessable_entity
  end

  test "non-admin cannot access menus endpoints" do
    delete session_path
    post session_path, params: { email_address: "user@example.com", password: "password" }

    get system_menus_url(format: :json)
    assert_response :forbidden
  end
end
