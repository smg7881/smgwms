require "test_helper"

class SearchPopupsWmLocationFiltersTest < ActionDispatch::IntegrationTest
  setup do
    post session_path, params: { email_address: "admin@example.com", password: "password" }

    WmWorkplace.create!(workpl_cd: "WP1", workpl_nm: "센터1", use_yn: "Y")
    WmWorkplace.create!(workpl_cd: "WP2", workpl_nm: "센터2", use_yn: "Y")

    WmArea.create!(workpl_cd: "WP1", area_cd: "A01", area_nm: "영역1", use_yn: "Y")
    WmArea.create!(workpl_cd: "WP2", area_cd: "A02", area_nm: "영역2", use_yn: "Y")

    WmZone.create!(workpl_cd: "WP1", area_cd: "A01", zone_cd: "Z01", zone_nm: "구역1", use_yn: "Y")
    WmZone.create!(workpl_cd: "WP1", area_cd: "A01", zone_cd: "Z02", zone_nm: "구역2", use_yn: "Y")
    WmZone.create!(workpl_cd: "WP2", area_cd: "A02", zone_cd: "Z90", zone_nm: "구역90", use_yn: "Y")

    WmLocation.create!(workpl_cd: "WP1", area_cd: "A01", zone_cd: "Z01", loc_cd: "L001", loc_nm: "로케이션1", use_yn: "Y")
    WmLocation.create!(workpl_cd: "WP1", area_cd: "A01", zone_cd: "Z02", loc_cd: "L002", loc_nm: "로케이션2", use_yn: "Y")
    WmLocation.create!(workpl_cd: "WP2", area_cd: "A02", zone_cd: "Z90", loc_cd: "L900", loc_nm: "로케이션900", use_yn: "Y")
  end

  test "area popup is filtered by workpl_cd" do
    get search_popup_path("area"), params: { format: :json, workpl_cd: "WP1" }

    assert_response :success
    rows = JSON.parse(response.body)
    assert_equal [ "A01" ], rows.map { |row| row["code"] }
  end

  test "zone popup is filtered by workpl_cd and area_cd" do
    get search_popup_path("zone"), params: { format: :json, workpl_cd: "WP1", area_cd: "A01" }

    assert_response :success
    rows = JSON.parse(response.body)
    assert_equal [ "Z01", "Z02" ], rows.map { |row| row["code"] }.sort
  end

  test "location popup is filtered by workpl_cd, area_cd and zone_cd" do
    get search_popup_path("location"), params: {
      format: :json,
      workpl_cd: "WP1",
      area_cd: "A01",
      zone_cd: "Z01"
    }

    assert_response :success
    rows = JSON.parse(response.body)
    assert_equal [ "L001" ], rows.map { |row| row["code"] }
  end
end
