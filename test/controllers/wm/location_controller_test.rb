require "test_helper"

class Wm::LocationControllerTest < ActionDispatch::IntegrationTest
  setup do
    post session_path, params: { email_address: "admin@example.com", password: "password" }

    WmWorkplace.create!(workpl_cd: "WP_A", workpl_nm: "Workplace A", use_yn: "Y")
    WmWorkplace.create!(workpl_cd: "WP_B", workpl_nm: "Workplace B", use_yn: "Y")
    WmArea.create!(workpl_cd: "WP_A", area_cd: "A01", area_nm: "Area A", use_yn: "Y")
    WmArea.create!(workpl_cd: "WP_B", area_cd: "B01", area_nm: "Area B", use_yn: "Y")
    WmZone.create!(workpl_cd: "WP_A", area_cd: "A01", zone_cd: "Z01", zone_nm: "Zone A", use_yn: "Y")
    WmZone.create!(workpl_cd: "WP_B", area_cd: "B01", zone_cd: "Z10", zone_nm: "Zone B", use_yn: "Y")
  end

  test "index responds to html" do
    get wm_location_index_url(q: { workpl_cd: "WP_A", area_cd: "A01", zone_cd: "Z01", use_yn: "Y" })
    assert_response :success
  end

  test "index responds to json" do
    WmLocation.create!(
      workpl_cd: "WP_A",
      area_cd: "A01",
      zone_cd: "Z01",
      loc_cd: "L01",
      loc_nm: "Location A",
      use_yn: "Y"
    )

    get wm_location_index_url(format: :json), params: {
      q: { workpl_cd: "WP_A", area_cd: "A01", zone_cd: "Z01", use_yn: "Y" }
    }
    assert_response :success

    rows = JSON.parse(response.body)
    assert_equal "WP_A", rows.first["workpl_cd"]
    assert_equal "L01", rows.first["loc_cd"]
  end

  test "index json supports workplace-only search" do
    WmLocation.create!(
      workpl_cd: "WP_A",
      area_cd: "A01",
      zone_cd: "Z01",
      loc_cd: "L11",
      loc_nm: "Location 11",
      use_yn: "Y"
    )
    WmLocation.create!(
      workpl_cd: "WP_B",
      area_cd: "B01",
      zone_cd: "Z10",
      loc_cd: "L12",
      loc_nm: "Location 12",
      use_yn: "Y"
    )

    get wm_location_index_url(format: :json), params: {
      q: { workpl_cd: "WP_A", area_cd: "", zone_cd: "", use_yn: "Y" }
    }
    assert_response :success

    rows = JSON.parse(response.body)
    assert_equal 1, rows.size
    assert_equal "WP_A", rows.first["workpl_cd"]
    assert_equal "L11", rows.first["loc_cd"]
  end

  test "areas responds to json" do
    get areas_wm_location_index_url(format: :json), params: { workpl_cd: "WP_A" }
    assert_response :success

    rows = JSON.parse(response.body)
    assert_equal "A01", rows.first["area_cd"]
  end

  test "zones responds to json" do
    get zones_wm_location_index_url(format: :json), params: { workpl_cd: "WP_A", area_cd: "A01", use_yn: "Y" }
    assert_response :success

    rows = JSON.parse(response.body)
    assert_equal "Z01", rows.first["zone_cd"]
  end

  test "batch_save inserts updates and deletes" do
    WmLocation.create!(
      workpl_cd: "WP_A",
      area_cd: "A01",
      zone_cd: "Z01",
      loc_cd: "L_UPD",
      loc_nm: "Before Update",
      use_yn: "Y",
      has_stock: "N"
    )
    WmLocation.create!(
      workpl_cd: "WP_A",
      area_cd: "A01",
      zone_cd: "Z01",
      loc_cd: "L_DEL",
      loc_nm: "Delete Target",
      use_yn: "Y",
      has_stock: "N"
    )

    post batch_save_wm_location_index_url, params: {
      rowsToInsert: [
        { workpl_cd: "WP_A", area_cd: "A01", zone_cd: "Z01", loc_cd: "L_NEW", loc_nm: "New Location", loc_class_cd: "STORAGE", loc_type_cd: "NORMAL", use_yn: "Y", has_stock: "N" }
      ],
      rowsToUpdate: [
        { workpl_cd: "WP_A", area_cd: "A01", zone_cd: "Z01", loc_cd: "L_UPD", loc_nm: "Updated Location", loc_class_cd: "PICKING", use_yn: "N", has_stock: "N" }
      ],
      rowsToDelete: [
        { workpl_cd: "WP_A", area_cd: "A01", zone_cd: "Z01", loc_cd: "L_DEL" }
      ]
    }, as: :json

    assert_response :success
    assert_equal "New Location", WmLocation.find_by!(workpl_cd: "WP_A", area_cd: "A01", zone_cd: "Z01", loc_cd: "L_NEW").loc_nm
    assert_equal "Updated Location", WmLocation.find_by!(workpl_cd: "WP_A", area_cd: "A01", zone_cd: "Z01", loc_cd: "L_UPD").loc_nm
    assert_equal "N", WmLocation.find_by!(workpl_cd: "WP_A", area_cd: "A01", zone_cd: "Z01", loc_cd: "L_UPD").use_yn
    assert_not WmLocation.exists?(workpl_cd: "WP_A", area_cd: "A01", zone_cd: "Z01", loc_cd: "L_DEL")
  end

  test "batch_save rejects deleting stocked locations" do
    WmLocation.create!(
      workpl_cd: "WP_A",
      area_cd: "A01",
      zone_cd: "Z01",
      loc_cd: "L_STOCK",
      loc_nm: "Stocked",
      use_yn: "Y",
      has_stock: "Y"
    )

    post batch_save_wm_location_index_url, params: {
      rowsToInsert: [],
      rowsToUpdate: [],
      rowsToDelete: [
        { workpl_cd: "WP_A", area_cd: "A01", zone_cd: "Z01", loc_cd: "L_STOCK" }
      ]
    }, as: :json

    assert_response :unprocessable_entity
    assert WmLocation.exists?(workpl_cd: "WP_A", area_cd: "A01", zone_cd: "Z01", loc_cd: "L_STOCK")
  end

  test "non-admin without permission cannot access endpoints" do
    user = User.find_by!(email_address: "user@example.com")
    permission = AdmUserMenuPermission.find_or_initialize_by(user: user, menu_cd: "WM_LOCATION")
    permission.use_yn = "N"
    permission.save!

    delete session_path
    post session_path, params: { email_address: "user@example.com", password: "password" }

    get wm_location_index_url(format: :json), params: {
      q: { workpl_cd: "WP_A", area_cd: "A01", zone_cd: "Z01", use_yn: "Y" }
    }
    assert_response :forbidden
  end

  test "non-admin with permission can access endpoints" do
    user = User.find_by!(email_address: "user@example.com")
    permission = AdmUserMenuPermission.find_or_initialize_by(user: user, menu_cd: "WM_LOCATION")
    permission.use_yn = "Y"
    permission.save!

    delete session_path
    post session_path, params: { email_address: "user@example.com", password: "password" }

    get wm_location_index_url(format: :json), params: {
      q: { workpl_cd: "WP_A", area_cd: "A01", zone_cd: "Z01", use_yn: "Y" }
    }
    assert_response :success
  end
end
