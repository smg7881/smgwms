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
    delete system_menu_url(adm_menus(:main)), as: :json
    assert_response :unprocessable_entity
  end
end
