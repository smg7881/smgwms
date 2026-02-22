require "test_helper"

class Std::CorporationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    post session_path, params: { email_address: "admin@example.com", password: "password" }
  end

  test "index responds to html and json" do
    StdCorporation.create!(
      corp_cd: "CP000001",
      corp_nm: "Corp A",
      indstype_cd: "Industry",
      bizcond_cd: "Condition",
      rptr_nm_cd: "CEO",
      use_yn_cd: "Y"
    )

    get std_corporations_url
    assert_response :success

    get std_corporations_url(format: :json)
    assert_response :success
    rows = JSON.parse(response.body)
    assert rows.any? { |row| row["corp_cd"] == "CP000001" }
  end

  test "batch_save inserts updates and soft deletes with history" do
    StdCorporation.create!(
      corp_cd: "CP000010",
      corp_nm: "Before",
      indstype_cd: "Industry",
      bizcond_cd: "Condition",
      rptr_nm_cd: "CEO",
      use_yn_cd: "Y"
    )
    StdCorporation.create!(
      corp_cd: "CP000011",
      corp_nm: "Delete Target",
      indstype_cd: "Industry",
      bizcond_cd: "Condition",
      rptr_nm_cd: "CEO",
      use_yn_cd: "Y"
    )

    post batch_save_std_corporations_url, params: {
      rowsToInsert: [
        { corp_nm: "New Corp", indstype_cd: "IND", bizcond_cd: "BIZ", rptr_nm_cd: "NEW", use_yn_cd: "Y" }
      ],
      rowsToUpdate: [
        { corp_cd: "CP000010", corp_nm: "After", indstype_cd: "Industry", bizcond_cd: "Condition", rptr_nm_cd: "CEO", use_yn_cd: "Y" }
      ],
      rowsToDelete: ["CP000011"]
    }, as: :json

    assert_response :success
    assert_equal "After", StdCorporation.find_by!(corp_cd: "CP000010").corp_nm
    assert_equal "N", StdCorporation.find_by!(corp_cd: "CP000011").use_yn_cd
    assert StdCorporation.exists?(corp_nm: "New Corp")
    assert StdCorporationHistory.where(corp_cd: "CP000010", changed_col_nm: "corp_nm").exists?
  end

  test "country info batch save validates only one representative per corporation" do
    corp = StdCorporation.create!(
      corp_cd: "CP000020",
      corp_nm: "Corp B",
      indstype_cd: "Industry",
      bizcond_cd: "Condition",
      rptr_nm_cd: "CEO",
      use_yn_cd: "Y"
    )
    StdCorporationCountry.create!(
      corp_cd: corp.corp_cd,
      seq: 1,
      ctry_cd: "KR",
      rpt_yn_cd: "Y",
      use_yn_cd: "Y"
    )

    post batch_save_country_infos_std_corporation_url(corp.corp_cd), params: {
      rowsToInsert: [{ ctry_cd: "US", rpt_yn_cd: "Y", use_yn_cd: "Y" }],
      rowsToUpdate: [],
      rowsToDelete: []
    }, as: :json

    assert_response :unprocessable_entity
    body = JSON.parse(response.body)
    assert_includes body["errors"].join(" "), "법인별 대표 국가는 1개만 설정할 수 있습니다."
  end

  test "country infos endpoint returns rows for selected corporation" do
    corp = StdCorporation.create!(
      corp_cd: "CP000021",
      corp_nm: "Corp C",
      indstype_cd: "Industry",
      bizcond_cd: "Condition",
      rptr_nm_cd: "CEO",
      use_yn_cd: "Y"
    )
    StdCorporationCountry.create!(corp_cd: corp.corp_cd, seq: 1, ctry_cd: "KR", use_yn_cd: "Y")

    get country_infos_std_corporation_url(corp.corp_cd, format: :json)
    assert_response :success
    rows = JSON.parse(response.body)
    assert_equal "KR", rows.first["ctry_cd"]
  end

  test "non-admin requires menu permission" do
    delete session_path
    user = User.find_by!(email_address: "user@example.com")
    AdmUserMenuPermission.where(user_id: user.id, menu_cd: "STD_CORPORATION").delete_all
    post session_path, params: { email_address: "user@example.com", password: "password" }

    get std_corporations_url(format: :json)
    assert_response :forbidden

    AdmUserMenuPermission.create!(user: user, menu_cd: "STD_CORPORATION", use_yn: "Y")
    get std_corporations_url(format: :json)
    assert_response :success
  end
end
