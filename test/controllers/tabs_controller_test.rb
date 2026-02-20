require "test_helper"

class TabsControllerTest < ActionDispatch::IntegrationTest
  setup do
    post session_path, params: { email_address: "admin@example.com", password: "password" }
  end

  test "POST /tabs records menu access log" do
    assert_difference("AdmMenuLog.count", 1) do
      post tabs_url,
        params: { tab: { id: "system-menus", label: "Menu", url: "/system/menus" } },
        headers: turbo_stream_headers
    end

    log = AdmMenuLog.order(:id).last
    assert_equal "system-menus", log.menu_id
    assert_equal "/system/menus", log.menu_path
    assert_equal "admin01", log.user_id
  end

  test "POST /tabs/:id/activation records menu access log" do
    open_tab("system-users", "/system/users")

    assert_difference("AdmMenuLog.count", 1) do
      post tab_activation_url("system-users"), headers: turbo_stream_headers
    end

    log = AdmMenuLog.order(:id).last
    assert_equal "system-users", log.menu_id
    assert_equal "/system/users", log.menu_path
    assert_equal "admin01", log.user_id
  end

  test "POST /tabs returns unprocessable entity when opening more than 10 tabs" do
    9.times do |index|
      open_tab("extra-#{index}", "/extra/#{index}")
    end

    assert_no_difference("AdmMenuLog.count") do
      post tabs_url,
        params: { tab: { id: "extra-over-limit", label: "Extra Over Limit", url: "/extra/over-limit" } },
        headers: turbo_stream_headers
    end

    assert_response :unprocessable_entity
  end

  test "DELETE /tabs/close_all keeps overview tab only" do
    open_tab("system-users", "/system/users")
    open_tab("system-menus", "/system/menus")

    delete close_all_tabs_url, headers: turbo_stream_headers

    assert_response :success
    assert_includes response.body, 'data-tab-id="overview"'
    assert_not_includes response.body, 'data-tab-id="system-users"'
    assert_not_includes response.body, 'data-tab-id="system-menus"'
  end

  test "DELETE /tabs/close_others keeps requested tab and overview" do
    open_tab("system-users", "/system/users")
    open_tab("system-menus", "/system/menus")

    delete close_others_tabs_url(id: "system-users"), headers: turbo_stream_headers

    assert_response :success
    assert_includes response.body, 'data-tab-id="overview"'
    assert_includes response.body, 'data-tab-id="system-users"'
    assert_not_includes response.body, 'data-tab-id="system-menus"'
  end

  test "PATCH /tabs/:id/move_left moves tab one position left" do
    open_tab("system-users", "/system/users")
    open_tab("system-menus", "/system/menus")

    patch move_left_tab_url("system-menus"), headers: turbo_stream_headers

    assert_response :success
    assert_equal [ "overview", "system-menus", "system-users" ], unique_tab_ids_in_response.first(3)
  end

  test "PATCH /tabs/:id/move_right moves tab one position right" do
    open_tab("system-users", "/system/users")
    open_tab("system-menus", "/system/menus")

    patch move_right_tab_url("system-users"), headers: turbo_stream_headers

    assert_response :success
    assert_equal [ "overview", "system-menus", "system-users" ], unique_tab_ids_in_response.first(3)
  end

  private
    def open_tab(id, url)
      post tabs_url,
        params: { tab: { id: id, label: id.humanize, url: url } },
        headers: turbo_stream_headers
    end

    def turbo_stream_headers
      { "Accept" => "text/vnd.turbo-stream.html" }
    end

    def unique_tab_ids_in_response
      response.body.scan(/data-tab-id="([^"]+)"/).flatten.uniq
    end
end
