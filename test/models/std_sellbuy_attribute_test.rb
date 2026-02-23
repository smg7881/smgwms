require "test_helper"

class StdSellbuyAttributeTest < ActiveSupport::TestCase
  test "normalizes fields and auto assigns code" do
    row = StdSellbuyAttribute.create!(
      corp_cd: " c001 ",
      sellbuy_sctn_cd: " sell ",
      sellbuy_attr_nm: " 운송료 ",
      rdtn_nm: " 운송 ",
      sellbuy_attr_eng_nm: " freight charge ",
      use_yn_cd: "y"
    )

    assert_equal "C001", row.corp_cd
    assert_equal "SELL", row.sellbuy_sctn_cd
    assert_equal "운송료", row.sellbuy_attr_nm
    assert_equal "운송", row.rdtn_nm
    assert_equal "freight charge", row.sellbuy_attr_eng_nm
    assert_match(/\A\d{8}\z/, row.sellbuy_attr_cd)
    assert_equal "Y", row.use_yn_cd
  end

  test "validates upper attribute is not itself" do
    row = StdSellbuyAttribute.new(
      corp_cd: "C001",
      sellbuy_attr_cd: "00000001",
      upper_sellbuy_attr_cd: "00000001",
      sellbuy_attr_nm: "매출수수료",
      rdtn_nm: "수수료",
      sellbuy_attr_eng_nm: "commission"
    )

    assert_not row.valid?
    assert_includes row.errors[:upper_sellbuy_attr_cd].join(" "), "같을 수 없습니다"
  end
end
