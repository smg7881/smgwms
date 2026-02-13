require "test_helper"

class AuthenticationTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
  end

  test "unauthenticated user is redirected to login" do
    get root_path
    assert_redirected_to new_session_path
  end

  test "authenticated user can access protected pages" do
    sign_in_as @user
    get root_path
    assert_response :success
  end

  test "login then access original page" do
    get posts_path
    assert_redirected_to new_session_path

    post session_path, params: { email_address: "user@example.com", password: "password" }
    assert_redirected_to posts_path
    follow_redirect!
    assert_response :success
  end

  test "logout prevents access to protected pages" do
    sign_in_as @user
    delete session_path
    assert_redirected_to new_session_path

    get root_path
    assert_redirected_to new_session_path
  end

  private
    def sign_in_as(user)
      post session_path, params: { email_address: user.email_address, password: "password" }
      follow_redirect!
    end
end
