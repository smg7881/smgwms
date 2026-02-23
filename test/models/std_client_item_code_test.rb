require "test_helper"

class StdClientItemCodeTest < ActiveSupport::TestCase
  test "normalizes code fields and defaults yn values" do
    row = StdClientItemCode.create!(
      item_cd: " item-001 ",
      item_nm: " 아이템A ",
      bzac_cd: " c001 ",
      goodsnm_cd: " goods01 ",
      danger_yn_cd: "y",
      png_yn_cd: "",
      mstair_lading_yn_cd: nil,
      if_yn_cd: " n ",
      use_yn_cd: "",
      prod_nm_cd: " 제조사 "
    )

    assert_equal "ITEM-001", row.item_cd
    assert_equal "아이템A", row.item_nm
    assert_equal "C001", row.bzac_cd
    assert_equal "GOODS01", row.goodsnm_cd
    assert_equal "Y", row.danger_yn_cd
    assert_equal "N", row.png_yn_cd
    assert_equal "N", row.mstair_lading_yn_cd
    assert_equal "N", row.if_yn_cd
    assert_equal "Y", row.use_yn_cd
    assert_equal "제조사", row.prod_nm_cd
    assert row.reg_date.present?
    assert row.chgdt.present?
  end

  test "requires required fields" do
    row = StdClientItemCode.new

    assert_not row.valid?
    assert_includes row.errors[:item_cd], "can't be blank"
    assert_includes row.errors[:item_nm], "can't be blank"
    assert_includes row.errors[:bzac_cd], "can't be blank"
    assert_includes row.errors[:goodsnm_cd], "can't be blank"
    assert_includes row.errors[:prod_nm_cd], "can't be blank"
  end
end
