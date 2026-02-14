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

  test "new renders resource form" do
    get new_post_url
    assert_response :success
    assert_includes response.body, 'data-controller="resource-form"'
    assert_includes response.body, 'name="post[title]"'
    assert_includes response.body, 'name="post[content]"'
  end

  test "edit renders resource form with submit label" do
    post = Post.create!(title: "제목", content: "내용")
    get edit_post_url(post)
    assert_response :success
    assert_includes response.body, "수정하기"
  end
end
