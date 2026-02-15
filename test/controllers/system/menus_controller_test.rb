require "test_helper"

class System::MenusControllerTest < ActionDispatch::IntegrationTest
  setup do
    post session_path, params: { email_address: "user@example.com", password: "password" }
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
end
