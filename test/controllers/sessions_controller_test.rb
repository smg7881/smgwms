require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
  end

  test "GET /session/new renders login page" do
    get new_session_path
    assert_response :success
  end

  test "GET /session/new is accessible when already authenticated" do
    cookies[:session_token] = sign_cookie(sessions(:one).token)
    get new_session_path
    assert_response :success
  end

  test "POST /session with valid credentials redirects to root" do
    post session_path, params: { email_address: "user@example.com", password: "password" }
    assert_redirected_to root_path
    assert cookies[:session_token].present?
  end

  test "POST /session with wrong password renders 422" do
    post session_path, params: { email_address: "user@example.com", password: "wrong" }
    assert_response :unprocessable_entity
  end

  test "POST /session with non-existent email renders 422" do
    post session_path, params: { email_address: "nobody@example.com", password: "password" }
    assert_response :unprocessable_entity
  end

  test "POST /session redirects to original URL after login" do
    get posts_path
    assert_redirected_to new_session_path

    post session_path, params: { email_address: "user@example.com", password: "password" }
    assert_redirected_to posts_path
  end

  test "DELETE /session destroys session and redirects to login" do
    cookies[:session_token] = sign_cookie(sessions(:one).token)
    delete session_path
    assert_redirected_to new_session_path
  end

  private
    def sign_cookie(value)
      verifier = ActiveSupport::MessageVerifier.new(
        Rails.application.secret_key_base,
        serializer: ActiveSupport::MessageEncryptor::NullSerializer
      )
      verifier.generate(value.to_s)
    end
end
