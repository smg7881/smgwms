require "test_helper"

class Wm::AreaControllerTest < ActionDispatch::IntegrationTest
  setup do
    post session_path, params: { email_address: "admin@example.com", password: "password" }
    WmWorkplace.create!(workpl_cd: "WP_A", workpl_nm: "작업장A", use_yn: "Y")
    WmWorkplace.create!(workpl_cd: "WP_B", workpl_nm: "작업장B", use_yn: "Y")
  end

  test "index responds to html" do
    get wm_area_index_url
    assert_response :success
  end

  test "index responds to json" do
    WmArea.create!(workpl_cd: "WP_A", area_cd: "A01", area_nm: "입고", use_yn: "Y")

    get wm_area_index_url(format: :json)
    assert_response :success

    rows = JSON.parse(response.body)
    assert_equal "WP_A", rows.first["workpl_cd"]
    assert_equal "A01", rows.first["area_cd"]
  end

  test "batch_save inserts updates and deletes" do
    WmArea.create!(workpl_cd: "WP_A", area_cd: "A10", area_nm: "수정전", use_yn: "Y")
    WmArea.create!(workpl_cd: "WP_B", area_cd: "B10", area_nm: "삭제대상", use_yn: "Y")

    post batch_save_wm_area_index_url, params: {
      rowsToInsert: [
        { workpl_cd: "WP_A", area_cd: "A20", area_nm: "신규구역", area_desc: "신규설명", use_yn: "Y" }
      ],
      rowsToUpdate: [
        { workpl_cd: "WP_A", area_cd: "A10", area_nm: "수정완료", area_desc: "수정설명", use_yn: "N" }
      ],
      rowsToDelete: [
        { workpl_cd: "WP_B", area_cd: "B10" }
      ]
    }, as: :json

    assert_response :success
    assert_equal "신규구역", WmArea.find_by!(workpl_cd: "WP_A", area_cd: "A20").area_nm
    assert_equal "수정완료", WmArea.find_by!(workpl_cd: "WP_A", area_cd: "A10").area_nm
    assert_equal "N", WmArea.find_by!(workpl_cd: "WP_A", area_cd: "A10").use_yn
    assert_not WmArea.exists?(workpl_cd: "WP_B", area_cd: "B10")
  end

  test "non-admin without permission cannot access endpoints" do
    delete session_path
    post session_path, params: { email_address: "user@example.com", password: "password" }

    get wm_area_index_url(format: :json)
    assert_response :forbidden
  end

  test "non-admin with permission can access endpoints" do
    user = User.find_by!(email_address: "user@example.com")
    AdmUserMenuPermission.create!(user: user, menu_cd: "WM_AREA", use_yn: "Y")

    delete session_path
    post session_path, params: { email_address: "user@example.com", password: "password" }

    get wm_area_index_url(format: :json)
    assert_response :success
  end
end
