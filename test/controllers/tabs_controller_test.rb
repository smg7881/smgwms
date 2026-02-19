require "test_helper"

class TabsControllerTest < ActionDispatch::IntegrationTest
  setup do
    post session_path, params: { email_address: "admin@example.com", password: "password" }
  end

  test "POST /tabs records menu access log" do
    assert_difference("AdmMenuLog.count", 1) do
      post tabs_url,
        params: { tab: { id: "system-menus", label: "메뉴관리", url: "/system/menus" } },
        headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end

    log = AdmMenuLog.order(:id).last
    assert_equal "system-menus", log.menu_id
    assert_equal "메뉴관리", log.menu_name
    assert_equal "/system/menus", log.menu_path
    assert_equal "admin01", log.user_id
  end

  test "POST /tabs/:id/activation records menu access log" do
    post tabs_url,
      params: { tab: { id: "system-users", label: "사용자관리", url: "/system/users" } },
      headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_difference("AdmMenuLog.count", 1) do
      post tab_activation_url("system-users"),
        headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end

    log = AdmMenuLog.order(:id).last
    assert_equal "system-users", log.menu_id
    assert_equal "/system/users", log.menu_path
    assert_equal "admin01", log.user_id
  end
end
