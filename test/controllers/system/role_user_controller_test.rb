require "test_helper"

class System::RoleUserControllerTest < ActionDispatch::IntegrationTest
  setup do
    post session_path, params: { email_address: "admin@example.com", password: "password" }
    AdmRole.find_or_create_by!(role_cd: "MANAGER") do |role|
      role.role_nm = "관리자"
      role.use_yn = "Y"
    end
  end

  test "index responds to html" do
    get system_role_user_index_url
    assert_response :success
  end

  test "returns available and assigned users by role" do
    assigned_user = User.create!(
      email_address: "assigned-role-user@example.com",
      user_id_code: "asg001",
      user_nm: "할당사용자",
      role_cd: "MANAGER",
      password: "password"
    )
    available_user = User.create!(
      email_address: "available-role-user@example.com",
      user_id_code: "avl001",
      user_nm: "미할당사용자",
      role_cd: nil,
      password: "password"
    )

    get assigned_users_system_role_user_index_url, params: { role_cd: "MANAGER" }, as: :json
    assert_response :success
    assigned = JSON.parse(response.body)
    assigned_ids = assigned.map { |row| row["user_id_code"] }
    assert_includes assigned_ids, assigned_user.user_id_code

    get available_users_system_role_user_index_url, params: { role_cd: "MANAGER" }, as: :json
    assert_response :success
    available = JSON.parse(response.body)
    available_ids = available.map { |row| row["user_id_code"] }
    assert_includes available_ids, available_user.user_id_code
  end

  test "save_assignments updates role users" do
    target_user = User.create!(
      email_address: "target-role-user@example.com",
      user_id_code: "trg001",
      user_nm: "저장대상",
      role_cd: nil,
      password: "password"
    )
    removed_user = User.create!(
      email_address: "remove-role-user@example.com",
      user_id_code: "rmv001",
      user_nm: "해제대상",
      role_cd: "MANAGER",
      password: "password"
    )

    post save_assignments_system_role_user_index_url, params: {
      role_cd: "MANAGER",
      user_ids: [ target_user.user_id_code ]
    }, as: :json

    assert_response :success
    assert_equal "MANAGER", target_user.reload.role_cd
    assert_nil removed_user.reload.role_cd
  end

  test "non-admin cannot access role user endpoints" do
    delete session_path
    post session_path, params: { email_address: "user@example.com", password: "password" }

    get assigned_users_system_role_user_index_url, params: { role_cd: "MANAGER" }, as: :json
    assert_response :forbidden
  end
end
