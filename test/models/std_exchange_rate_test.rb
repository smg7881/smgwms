require "test_helper"

class StdExchangeRateTest < ActiveSupport::TestCase
  test "normalizes key fields and enforces uniqueness" do
    StdExchangeRate.create!(
      ctry_cd: "kr",
      fnc_or_cd: "kdb",
      std_ymd: Date.current,
      anno_dgrcnt: "first",
      mon_cd: "usd",
      use_yn_cd: "y"
    )

    duplicate = StdExchangeRate.new(
      ctry_cd: "KR",
      fnc_or_cd: "KDB",
      std_ymd: Date.current,
      anno_dgrcnt: "FIRST",
      mon_cd: "USD",
      use_yn_cd: "Y"
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:mon_cd], "has already been taken"
  end
end
