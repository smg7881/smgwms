require "test_helper"

class System::UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    post session_path, params: { email_address: "admin@example.com", password: "password" }
  end

  test "index json does not expose password_digest" do
    get system_users_url(format: :json)
    assert_response :success

    json = JSON.parse(response.body)
    assert_operator json.length, :>=, 1
    assert_not_includes json.first.keys, "password_digest"
  end

  test "show json does not expose password_digest" do
    get system_user_url(users(:one), format: :json)
    assert_response :success

    json = JSON.parse(response.body)
    assert_not_includes json.keys, "password_digest"
  end

  test "non-admin cannot access users endpoints" do
    delete session_path
    post session_path, params: { email_address: "user@example.com", password: "password" }

    get system_users_url(format: :json)
    assert_response :forbidden
  end
end
