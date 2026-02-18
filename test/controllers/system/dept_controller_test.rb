require "test_helper"

class System::DeptControllerTest < ActionDispatch::IntegrationTest
  setup do
    post session_path, params: { email_address: "admin@example.com", password: "password" }
  end

  test "index responds to html" do
    get system_dept_index_url
    assert_response :success
  end

  test "index responds to json" do
    get system_dept_index_url(format: :json)
    assert_response :success

    json = JSON.parse(response.body)
    assert_operator json.length, :>=, 1
    assert_includes json.first.keys, "dept_code"
  end

  test "creates dept" do
    assert_difference("AdmDept.count", 1) do
      post system_dept_index_url, params: {
        dept: {
          dept_code: "QA",
          dept_nm: "품질팀",
          parent_dept_code: "HQ",
          dept_type: "TEAM",
          dept_order: 10,
          use_yn: "Y",
          description: "테스트 부서"
        }
      }, as: :json
    end

    assert_response :success
  end

  test "rejects delete when children exist" do
    delete system_dept_url("HQ"), as: :json
    assert_response :unprocessable_entity
  end

  test "non-admin cannot access dept endpoints" do
    delete session_path
    post session_path, params: { email_address: "user@example.com", password: "password" }

    get system_dept_index_url(format: :json)
    assert_response :forbidden
  end
end
