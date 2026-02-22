require "test_helper"

class StdCorporationCountryTest < ActiveSupport::TestCase
  setup do
    @corp = StdCorporation.create!(
      corp_cd: "CP900001",
      corp_nm: "Corp",
      indstype_cd: "Industry",
      bizcond_cd: "Condition",
      rptr_nm_cd: "CEO",
      use_yn_cd: "Y"
    )
  end

  test "assigns next seq when omitted" do
    StdCorporationCountry.create!(corp_cd: @corp.corp_cd, seq: 1, ctry_cd: "KR", use_yn_cd: "Y")

    row = StdCorporationCountry.create!(
      corp_cd: @corp.corp_cd,
      ctry_cd: "US",
      rpt_yn_cd: "n",
      use_yn_cd: "y"
    )

    assert_equal 2, row.seq
    assert_equal "N", row.rpt_yn_cd
    assert_equal "Y", row.use_yn_cd
  end
end
