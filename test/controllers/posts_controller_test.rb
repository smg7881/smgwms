require "test_helper"

class PostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    post session_path, params: { email_address: "user@example.com", password: "password" }
  end

  test "index responds to json" do
    Post.create!(title: "테스트", content: "내용")
    get posts_url, as: :json

    assert_response :success
    json = JSON.parse(response.body)
    assert_operator json.length, :>=, 1
    assert json.any? { |p| p["title"] == "테스트" }
  end
end
