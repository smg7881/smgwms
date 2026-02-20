require "test_helper"

class System::UserMenuRoleControllerTest < ActionDispatch::IntegrationTest
  setup do
    post session_path, params: { email_address: "admin@example.com", password: "password" }
    AdmRole.find_or_create_by!(role_cd: "MANAGER") do |role|
      role.role_nm = "매니저"
      role.use_yn = "Y"
    end
  end

  test "index responds to html" do
    get system_user_menu_role_index_url
    assert_response :success
  end

  test "users returns filtered result" do
    target_user = User.create!(
      email_address: "user-menu-role-target@example.com",
      user_id_code: "umr001",
      user_nm: "조회대상",
      dept_nm: "개발팀",
      password: "password"
    )
    User.create!(
      email_address: "user-menu-role-other@example.com",
      user_id_code: "umr002",
      user_nm: "기타사용자",
      dept_nm: "인사팀",
      password: "password"
    )

    get users_system_user_menu_role_index_url, params: { q: { user_nm: "조회" } }, as: :json
    assert_response :success

    rows = JSON.parse(response.body)
    ids = rows.map { |row| row["user_id_code"] }
    assert_includes ids, target_user.user_id_code
    assert_not_includes ids, "umr002"
  end

  test "roles_by_user returns selected user role" do
    user = User.create!(
      email_address: "user-menu-role-role@example.com",
      user_id_code: "umr003",
      user_nm: "역할대상",
      role_cd: "MANAGER",
      password: "password"
    )

    get roles_by_user_system_user_menu_role_index_url, params: { user_id_code: user.user_id_code }, as: :json
    assert_response :success

    rows = JSON.parse(response.body)
    assert_equal "MANAGER", rows.first["role_cd"]
  end

  test "menus_by_user_role returns active menus" do
    user = User.find_by!(user_id_code: "admin01")

    AdmMenu.create!(
      menu_cd: "UMR_MENU_Y",
      menu_nm: "활성메뉴",
      parent_cd: nil,
      menu_url: nil,
      menu_icon: nil,
      sort_order: 9991,
      menu_level: 1,
      menu_type: "FOLDER",
      use_yn: "Y",
      tab_id: nil
    )
    AdmMenu.create!(
      menu_cd: "UMR_MENU_N",
      menu_nm: "비활성메뉴",
      parent_cd: nil,
      menu_url: nil,
      menu_icon: nil,
      sort_order: 9992,
      menu_level: 1,
      menu_type: "FOLDER",
      use_yn: "N",
      tab_id: nil
    )

    AdmUserMenuPermission.create!(user: user, menu_cd: "UMR_MENU_Y", use_yn: "Y")
    AdmUserMenuPermission.create!(user: user, menu_cd: "UMR_MENU_N", use_yn: "N")

    get menus_by_user_role_system_user_menu_role_index_url, params: { user_id_code: "admin01", role_cd: "MANAGER" }, as: :json
    assert_response :success

    rows = JSON.parse(response.body)
    codes = rows.map { |row| row["menu_cd"] }
    assert_includes codes, "UMR_MENU_Y"
    assert_not_includes codes, "UMR_MENU_N"
  end

  test "non-admin cannot access user menu role endpoints" do
    delete session_path
    post session_path, params: { email_address: "user@example.com", password: "password" }

    get users_system_user_menu_role_index_url, as: :json
    assert_response :forbidden
  end
end
