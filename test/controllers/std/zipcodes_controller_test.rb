require "test_helper"

class Std::ZipcodesControllerTest < ActionDispatch::IntegrationTest
  setup do
    post session_path, params: { email_address: "admin@example.com", password: "password" }
  end

  test "index responds to html and json" do
    StdZipCode.create!(
      ctry_cd: "KR",
      zipcd: "77777",
      seq_no: 1,
      zipaddr: "서울특별시 중구",
      sido: "서울특별시",
      sgng: "중구",
      eupdiv: "무교동",
      use_yn_cd: "Y"
    )

    get std_zipcodes_url
    assert_response :success

    get std_zipcodes_url(format: :json), params: { q: { zipcd: "77777" } }
    assert_response :success
    rows = JSON.parse(response.body)
    assert rows.any? { |row| row["zipcd"] == "77777" }
  end

  test "create update and destroy work with modal endpoints" do
    post std_zipcodes_url, params: {
      zipcode: {
        authenticity_token: "token",
        ctry_lookup: "대한민국",
        ctry_cd: "KR",
        zipcd: "88990",
        seq_no: 1,
        zipaddr: "서울특별시 강남구 테헤란로 100",
        sido: "서울특별시",
        sgng: "강남구",
        eupdiv: "역삼동",
        addr_ri: "테스트리",
        iland_san: "산",
        apt_bild_nm: "테스트아파트",
        use_yn_cd: "Y"
      }
    }, as: :json

    assert_response :success
    row = StdZipCode.find_by!(ctry_cd: "KR", zipcd: "88990", seq_no: 1)
    assert_equal "역삼동", row.eupdiv
    assert_equal "테스트리", row.addr_ri
    assert_equal "산", row.iland_san
    assert_equal "테스트아파트", row.apt_bild_nm

    patch std_zipcode_url(row.id), params: {
      zipcode: {
        ctry_cd: "US",
        zipcd: "CHANGED",
        seq_no: 99,
        zipaddr: "수정된 우편주소",
        sido: "부산광역시",
        sgng: "해운대구",
        eupdiv: "우동",
        use_yn_cd: "N"
      }
    }, as: :json

    assert_response :success
    row.reload
    assert_equal "KR", row.ctry_cd
    assert_equal "88990", row.zipcd
    assert_equal 1, row.seq_no
    assert_equal "수정된 우편주소", row.zipaddr
    assert_equal "N", row.use_yn_cd

    delete std_zipcode_url(row.id), as: :json
    assert_response :success
    assert_equal "N", row.reload.use_yn_cd
  end

  test "non-admin requires menu permission" do
    delete session_path
    user = User.find_by!(email_address: "user@example.com")
    AdmUserMenuPermission.where(user_id: user.id, menu_cd: "STD_ZIP_CODE").delete_all
    post session_path, params: { email_address: "user@example.com", password: "password" }

    get std_zipcodes_url(format: :json)
    assert_response :forbidden

    AdmUserMenuPermission.create!(user: user, menu_cd: "STD_ZIP_CODE", use_yn: "Y")
    get std_zipcodes_url(format: :json)
    assert_response :success
  end
end
