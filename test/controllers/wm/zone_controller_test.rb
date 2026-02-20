require "test_helper"

class Wm::ZoneControllerTest < ActionDispatch::IntegrationTest
  setup do
    post session_path, params: { email_address: "admin@example.com", password: "password" }
    WmWorkplace.create!(workpl_cd: "WP_A", workpl_nm: "작업장A", use_yn: "Y")
    WmWorkplace.create!(workpl_cd: "WP_B", workpl_nm: "작업장B", use_yn: "Y")
    WmArea.create!(workpl_cd: "WP_A", area_cd: "A01", area_nm: "구역A", use_yn: "Y")
    WmArea.create!(workpl_cd: "WP_B", area_cd: "B01", area_nm: "구역B", use_yn: "Y")
  end

  test "index responds to html" do
    get wm_zone_index_url(q: { workpl_cd: "WP_A", use_yn: "Y" })
    assert_response :success
  end

  test "index responds to json" do
    get wm_zone_index_url(format: :json, q: { workpl_cd: "WP_A", use_yn: "Y" })
    assert_response :success

    rows = JSON.parse(response.body)
    assert_equal "WP_A", rows.first["workpl_cd"]
    assert_equal "A01", rows.first["area_cd"]
  end

  test "zones responds to json" do
    WmZone.create!(workpl_cd: "WP_A", area_cd: "A01", zone_cd: "Z01", zone_nm: "보관존", use_yn: "Y")

    get zones_wm_zone_index_url(format: :json), params: {
      workpl_cd: "WP_A",
      area_cd: "A01",
      use_yn: "Y"
    }
    assert_response :success

    rows = JSON.parse(response.body)
    assert_equal "WP_A", rows.first["workpl_cd"]
    assert_equal "A01", rows.first["area_cd"]
    assert_equal "Z01", rows.first["zone_cd"]
  end

  test "batch_save inserts updates and deletes" do
    WmZone.create!(workpl_cd: "WP_A", area_cd: "A01", zone_cd: "Z10", zone_nm: "수정전", use_yn: "Y")
    WmZone.create!(workpl_cd: "WP_A", area_cd: "A01", zone_cd: "Z20", zone_nm: "삭제대상", use_yn: "Y")

    post batch_save_wm_zone_index_url, params: {
      rowsToInsert: [
        { workpl_cd: "WP_A", area_cd: "A01", zone_cd: "Z30", zone_nm: "신규존", zone_desc: "신규설명", use_yn: "Y" }
      ],
      rowsToUpdate: [
        { workpl_cd: "WP_A", area_cd: "A01", zone_cd: "Z10", zone_nm: "수정완료", zone_desc: "수정설명", use_yn: "N" }
      ],
      rowsToDelete: [
        { workpl_cd: "WP_A", area_cd: "A01", zone_cd: "Z20" }
      ]
    }, as: :json

    assert_response :success
    assert_equal "신규존", WmZone.find_by!(workpl_cd: "WP_A", area_cd: "A01", zone_cd: "Z30").zone_nm
    assert_equal "수정완료", WmZone.find_by!(workpl_cd: "WP_A", area_cd: "A01", zone_cd: "Z10").zone_nm
    assert_equal "N", WmZone.find_by!(workpl_cd: "WP_A", area_cd: "A01", zone_cd: "Z10").use_yn
    assert_not WmZone.exists?(workpl_cd: "WP_A", area_cd: "A01", zone_cd: "Z20")
  end

  test "non-admin without permission cannot access endpoints" do
    delete session_path
    post session_path, params: { email_address: "user@example.com", password: "password" }

    get wm_zone_index_url(format: :json, q: { workpl_cd: "WP_A", use_yn: "Y" })
    assert_response :forbidden
  end

  test "non-admin with permission can access endpoints" do
    user = User.find_by!(email_address: "user@example.com")
    AdmUserMenuPermission.create!(user: user, menu_cd: "WM_ZONE", use_yn: "Y")

    delete session_path
    post session_path, params: { email_address: "user@example.com", password: "password" }

    get wm_zone_index_url(format: :json, q: { workpl_cd: "WP_A", use_yn: "Y" })
    assert_response :success
  end
end
