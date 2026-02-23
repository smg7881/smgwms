require "test_helper"

class StdFinancialInstitutionTest < ActiveSupport::TestCase
  test "normalizes fields and defaults use_yn_cd" do
    row = StdFinancialInstitution.create!(
      fnc_or_cd: " kdb ",
      fnc_or_nm: " 산업은행 ",
      fnc_or_eng_nm: " korea development bank ",
      ctry_cd: " kr "
    )

    assert_equal "KDB", row.fnc_or_cd
    assert_equal "산업은행", row.fnc_or_nm
    assert_equal "korea development bank", row.fnc_or_eng_nm
    assert_equal "KR", row.ctry_cd
    assert_equal "Y", row.use_yn_cd
  end

  test "enforces unique fnc_or_cd" do
    StdFinancialInstitution.create!(
      fnc_or_cd: "KDB",
      fnc_or_nm: "산업은행",
      fnc_or_eng_nm: "KDB",
      use_yn_cd: "Y"
    )

    duplicate = StdFinancialInstitution.new(
      fnc_or_cd: "kdb",
      fnc_or_nm: "중복",
      fnc_or_eng_nm: "DUPLICATE",
      use_yn_cd: "Y"
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:fnc_or_cd], "has already been taken"
  end
end
