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

  test "index json includes ancestor departments when filtered" do
    AdmDept.create!(
      dept_code: "DSR",
      dept_nm: "Dept Search Root",
      parent_dept_code: nil,
      dept_type: "HQ",
      dept_order: 80,
      use_yn: "Y"
    )
    AdmDept.create!(
      dept_code: "DSP",
      dept_nm: "Dept Search Parent",
      parent_dept_code: "DSR",
      dept_type: "TEAM",
      dept_order: 1,
      use_yn: "Y"
    )
    AdmDept.create!(
      dept_code: "DSL",
      dept_nm: "Dept Search Leaf",
      parent_dept_code: "DSP",
      dept_type: "PART",
      dept_order: 1,
      use_yn: "Y"
    )

    get system_dept_index_url(format: :json), params: { q: { dept_code: "DSL" } }
    assert_response :success

    json = JSON.parse(response.body)
    dept_codes = json.map { |dept| dept["dept_code"] }
    dept_levels = json.map { |dept| dept["dept_level"] }
    assert_equal [ "DSR", "DSP", "DSL" ], dept_codes
    assert_equal [ 1, 2, 3 ], dept_levels
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
