require "test_helper"

class Std::WorkplacesControllerTest < ActionDispatch::IntegrationTest
  setup do
    post session_path, params: { email_address: "admin@example.com", password: "password" }
  end

  test "index responds to html and json" do
    StdWorkplace.create!(
      corp_cd: "C001",
      workpl_cd: "WP0001",
      dept_cd: "DEPT01",
      workpl_nm: "작업장A",
      workpl_sctn_cd: "WORK",
      wm_yn_cd: "N",
      use_yn_cd: "Y"
    )

    get std_workplaces_url
    assert_response :success

    get std_workplaces_url(format: :json)
    assert_response :success
    rows = JSON.parse(response.body)
    assert rows.any? { |row| row["workpl_cd"] == "WP0001" }
  end

  test "create update and destroy work with modal endpoints" do
    post std_workplaces_url, params: {
      workplace: {
        corp_cd: "C001",
        workpl_cd: "WP0100",
        dept_cd: "DEPT01",
        workpl_nm: "신규작업장",
        workpl_sctn_cd: "WORK",
        wm_yn_cd: "N",
        use_yn_cd: "Y"
      }
    }, as: :json

    assert_response :success
    assert_equal "신규작업장", StdWorkplace.find_by!(workpl_cd: "WP0100").workpl_nm

    patch std_workplace_url("WP0100"), params: {
      workplace: {
        workpl_cd: "WP9999",
        dept_cd: "DEPT02",
        workpl_nm: "수정작업장",
        workpl_sctn_cd: "WORK",
        wm_yn_cd: "Y",
        use_yn_cd: "Y"
      }
    }, as: :json

    assert_response :success
    row = StdWorkplace.find_by!(workpl_cd: "WP0100")
    assert_equal "수정작업장", row.workpl_nm
    assert_equal "DEPT02", row.dept_cd
    assert_equal "Y", row.wm_yn_cd

    delete std_workplace_url("WP0100"), as: :json
    assert_response :success
    assert_equal "N", row.reload.use_yn_cd
  end

  test "create rejects same upper workplace code as workplace code" do
    post std_workplaces_url, params: {
      workplace: {
        corp_cd: "C001",
        workpl_cd: "WPSELF",
        upper_workpl_cd: "WPSELF",
        dept_cd: "DEPT01",
        workpl_nm: "자기참조작업장",
        workpl_sctn_cd: "WORK",
        wm_yn_cd: "N",
        use_yn_cd: "Y"
      }
    }, as: :json

    assert_response :unprocessable_entity
    body = JSON.parse(response.body)
    assert_includes body["errors"].join(" "), "동일"
  end

  test "batch_save inserts updates and soft deletes" do
    StdWorkplace.create!(
      corp_cd: "C001",
      workpl_cd: "WP0200",
      dept_cd: "DEPT01",
      workpl_nm: "Before",
      workpl_sctn_cd: "WORK",
      wm_yn_cd: "N",
      use_yn_cd: "Y"
    )
    StdWorkplace.create!(
      corp_cd: "C001",
      workpl_cd: "WP0201",
      dept_cd: "DEPT01",
      workpl_nm: "Delete",
      workpl_sctn_cd: "WORK",
      wm_yn_cd: "N",
      use_yn_cd: "Y"
    )

    post batch_save_std_workplaces_url, params: {
      rowsToInsert: [
        {
          corp_cd: "C001",
          workpl_cd: "WP0202",
          dept_cd: "DEPT02",
          workpl_nm: "New",
          workpl_sctn_cd: "WORK",
          wm_yn_cd: "N",
          use_yn_cd: "Y"
        }
      ],
      rowsToUpdate: [
        {
          workpl_cd: "WP0200",
          dept_cd: "DEPT03",
          workpl_nm: "After",
          workpl_sctn_cd: "WORK",
          wm_yn_cd: "Y",
          use_yn_cd: "Y"
        }
      ],
      rowsToDelete: [ "WP0201" ]
    }, as: :json

    assert_response :success
    assert_equal "After", StdWorkplace.find_by!(workpl_cd: "WP0200").workpl_nm
    assert_equal "N", StdWorkplace.find_by!(workpl_cd: "WP0201").use_yn_cd
    assert StdWorkplace.exists?(workpl_cd: "WP0202")
  end

  test "non-admin requires menu permission" do
    delete session_path
    user = User.find_by!(email_address: "user@example.com")
    AdmUserMenuPermission.where(user_id: user.id, menu_cd: "STD_WORKPLACE").delete_all
    post session_path, params: { email_address: "user@example.com", password: "password" }

    get std_workplaces_url(format: :json)
    assert_response :forbidden

    AdmUserMenuPermission.create!(user: user, menu_cd: "STD_WORKPLACE", use_yn: "Y")
    get std_workplaces_url(format: :json)
    assert_response :success
  end
end
