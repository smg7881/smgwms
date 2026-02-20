require "test_helper"

class Wm::WorkplaceControllerTest < ActionDispatch::IntegrationTest
  setup do
    post session_path, params: { email_address: "admin@example.com", password: "password" }
  end

  test "index responds to html" do
    get wm_workplace_index_url
    assert_response :success
  end

  test "index responds to json" do
    WmWorkplace.find_or_create_by!(workpl_cd: "WPA") do |workplace|
      workplace.workpl_nm = "A Workplace"
      workplace.use_yn = "Y"
    end

    get wm_workplace_index_url(format: :json)
    assert_response :success

    rows = JSON.parse(response.body)
    row = rows.find { |r| r["workpl_cd"] == "WPA" }
    assert_not_nil row
  end

  test "batch_save inserts updates and deletes" do
    WmWorkplace.find_or_create_by!(workpl_cd: "WP_UPD") do |workplace|
      workplace.workpl_nm = "Before Update"
      workplace.use_yn = "Y"
    end
    WmWorkplace.find_or_create_by!(workpl_cd: "WP_DEL") do |workplace|
      workplace.workpl_nm = "To Delete"
      workplace.use_yn = "Y"
    end

    post batch_save_wm_workplace_index_url, params: {
      rowsToInsert: [
        { workpl_cd: "WP_NEW", workpl_nm: "New Workplace", workpl_type: "WH", use_yn: "Y" }
      ],
      rowsToUpdate: [
        { workpl_cd: "WP_UPD", workpl_nm: "Updated", workpl_type: "FC", use_yn: "N" }
      ],
      rowsToDelete: [ "WP_DEL" ]
    }, as: :json

    assert_response :success
    assert_equal "New Workplace", WmWorkplace.find_by!(workpl_cd: "WP_NEW").workpl_nm
    assert_equal "Updated", WmWorkplace.find_by!(workpl_cd: "WP_UPD").workpl_nm
    assert_equal "N", WmWorkplace.find_by!(workpl_cd: "WP_UPD").use_yn
    assert_not WmWorkplace.exists?(workpl_cd: "WP_DEL")
  end

  test "non-admin without permission cannot access endpoints" do
    delete session_path
    post session_path, params: { email_address: "user@example.com", password: "password" }

    get wm_workplace_index_url(format: :json)
    assert_response :forbidden
  end

  test "non-admin with permission can access endpoints" do
    user = User.find_by!(email_address: "user@example.com")
    AdmUserMenuPermission.find_or_create_by!(user: user, menu_cd: "WM_WORKPLACE") do |permission|
      permission.use_yn = "Y"
    end

    delete session_path
    post session_path, params: { email_address: "user@example.com", password: "password" }

    get wm_workplace_index_url(format: :json)
    assert_response :success
  end
end
