require "test_helper"

class System::NoticeControllerTest < ActionDispatch::IntegrationTest
  setup do
    post session_path, params: { email_address: "admin@example.com", password: "password" }

    @notice = AdmNotice.create!(
      category_code: "GENERAL",
      title: "테스트 공지",
      content: "내용",
      is_top_fixed: "N",
      is_published: "Y"
    )
  end

  test "index responds to html" do
    get system_notice_index_url
    assert_response :success
  end

  test "index responds to json" do
    get system_notice_index_url(format: :json)
    assert_response :success

    json = JSON.parse(response.body)
    assert_operator json.length, :>=, 1
    assert_includes json.first.keys, "title"
  end

  test "show responds to json" do
    get system_notice_url(@notice), as: :json
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal @notice.id, json["id"]
  end

  test "creates notice" do
    assert_difference("AdmNotice.count", 1) do
      post system_notice_index_url, params: {
        notice: {
          category_code: "SYSTEM",
          title: "신규 공지",
          content: "공지 내용",
          is_top_fixed: "N",
          is_published: "Y"
        }
      }, as: :json
    end

    assert_response :success
  end

  test "updates notice" do
    patch system_notice_url(@notice), params: {
      notice: {
        title: "수정 공지",
        category_code: "GENERAL",
        content: "수정 내용",
        is_top_fixed: "Y",
        is_published: "Y"
      }
    }, as: :json

    assert_response :success
    assert_equal "수정 공지", @notice.reload.title
  end

  test "removes selected existing attachments on update" do
    file = fixture_file_upload("users_import_valid.csv", "text/csv")
    @notice.attachments.attach(file)
    attachment_id = @notice.attachments.attachments.first.id

    patch system_notice_url(@notice), params: {
      notice: {
        title: @notice.title,
        category_code: @notice.category_code,
        content: @notice.content,
        is_top_fixed: @notice.is_top_fixed,
        is_published: @notice.is_published,
        remove_attachment_ids: [ attachment_id ]
      }
    }, as: :json

    assert_response :success
    assert_equal 0, @notice.reload.attachments.count
  end

  test "bulk destroys notices" do
    another = AdmNotice.create!(
      category_code: "EVENT",
      title: "삭제 대상",
      content: "삭제",
      is_top_fixed: "N",
      is_published: "Y"
    )

    assert_difference("AdmNotice.count", -2) do
      delete bulk_destroy_system_notice_index_url, params: { ids: [ @notice.id, another.id ] }, as: :json
    end

    assert_response :success
  end

  test "non-admin cannot access notice endpoints" do
    delete session_path
    post session_path, params: { email_address: "user@example.com", password: "password" }

    get system_notice_index_url(format: :json)
    assert_response :forbidden
  end
end
