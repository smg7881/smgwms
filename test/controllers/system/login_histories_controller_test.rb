require "test_helper"

class System::LoginHistoriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    post session_path, params: { email_address: "admin@example.com", password: "password" }
  end

  test "index responds successfully for admin" do
    get system_login_histories_url
    assert_response :success
  end

  test "index json returns paginated data" do
    get system_login_histories_url(format: :json, page: 1, per_page: 10)
    assert_response :success

    json = JSON.parse(response.body)
    assert json.key?("rows")
    assert json.key?("total")
    assert_kind_of Array, json["rows"]
    assert_kind_of Integer, json["total"]
  end

  test "index json filters by login_success" do
    get system_login_histories_url(format: :json, q: { login_success: "true" })
    assert_response :success

    json = JSON.parse(response.body)
    json["rows"].each do |row|
      assert_equal true, row["login_success"]
    end
  end

  test "non-admin cannot access login histories" do
    delete session_path
    post session_path, params: { email_address: "user@example.com", password: "password" }

    get system_login_histories_url(format: :json)
    assert_response :forbidden
  end
end
