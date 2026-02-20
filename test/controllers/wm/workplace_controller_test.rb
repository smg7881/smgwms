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
    WmWorkplace.create!(workpl_cd: "WPA", workpl_nm: "A작업장", use_yn: "Y")

    get wm_workplace_index_url(format: :json)
    assert_response :success

    rows = JSON.parse(response.body)
    assert_equal "WPA", rows.first["workpl_cd"]
  end

  test "batch_save inserts updates and deletes" do
    WmWorkplace.create!(workpl_cd: "WP_UPD", workpl_nm: "수정전", use_yn: "Y")
    WmWorkplace.create!(workpl_cd: "WP_DEL", workpl_nm: "삭제대상", use_yn: "Y")

    post batch_save_wm_workplace_index_url, params: {
      rowsToInsert: [
        { workpl_cd: "WP_NEW", workpl_nm: "신규작업장", workpl_type: "WH", use_yn: "Y" }
      ],
      rowsToUpdate: [
        { workpl_cd: "WP_UPD", workpl_nm: "수정완료", workpl_type: "FC", use_yn: "N" }
      ],
      rowsToDelete: [ "WP_DEL" ]
    }, as: :json

    assert_response :success
    assert_equal "신규작업장", WmWorkplace.find_by!(workpl_cd: "WP_NEW").workpl_nm
    assert_equal "수정완료", WmWorkplace.find_by!(workpl_cd: "WP_UPD").workpl_nm
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
    AdmUserMenuPermission.create!(user: user, menu_cd: "WM_WORKPLACE", use_yn: "Y")

    delete session_path
    post session_path, params: { email_address: "user@example.com", password: "password" }

    get wm_workplace_index_url(format: :json)
    assert_response :success
  end
end
