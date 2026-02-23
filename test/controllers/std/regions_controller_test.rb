require "test_helper"
require "securerandom"

class Std::RegionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    post session_path, params: { email_address: "admin@example.com", password: "password" }
  end

  test "index json resolves corp and upper region names with normalized codes" do
    token = SecureRandom.random_number(1_000_000_000)
    corp_code = "ZZR#{token.to_s.rjust(9, '0')}"
    parent_regn_cd = format("9%09d", token)
    child_regn_cd = format("8%09d", token)

    StdCorporation.create!(
      corp_cd: corp_code,
      corp_nm: "CorpNameTest",
      indstype_cd: "IND",
      bizcond_cd: "BIZ",
      rptr_nm_cd: "CEO",
      use_yn_cd: "Y"
    ).update_column(:corp_cd, "#{corp_code}   ")

    parent = StdRegion.create!(
      corp_cd: corp_code,
      regn_cd: parent_regn_cd,
      regn_nm_cd: "ParentRegion",
      regn_eng_nm_cd: "PARENT",
      use_yn_cd: "Y"
    )
    parent.update_column(:regn_cd, "#{parent_regn_cd}   ")

    StdRegion.create!(
      corp_cd: corp_code,
      regn_cd: child_regn_cd,
      regn_nm_cd: "ChildRegion",
      regn_eng_nm_cd: "CHILD",
      upper_regn_cd: parent_regn_cd,
      use_yn_cd: "Y"
    )

    get std_regions_url(format: :json)
    assert_response :success

    rows = JSON.parse(response.body)
    row = rows.find { |item| item["regn_cd"] == child_regn_cd }

    assert_not_nil row
    assert_equal corp_code, row["corp_cd"]
    assert_equal "CorpNameTest", row["corp_nm"]
    assert_equal parent_regn_cd, row["upper_regn_cd"]
    assert_equal "ParentRegion", row["upper_regn_nm"]
  end
end
