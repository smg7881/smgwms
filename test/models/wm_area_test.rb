require "test_helper"

class WmAreaTest < ActiveSupport::TestCase
  setup do
    WmWorkplace.create!(workpl_cd: "WPA", workpl_nm: "작업장A", use_yn: "Y")
  end

  test "valid with required fields" do
    area = WmArea.new(
      workpl_cd: "WPA",
      area_cd: "A01",
      area_nm: "입고구역",
      use_yn: "Y"
    )

    assert area.valid?
  end

  test "normalizes code and text fields before validation" do
    area = WmArea.create!(
      workpl_cd: " wpa ",
      area_cd: " a01 ",
      area_nm: " 입고구역 ",
      area_desc: " 설명 ",
      use_yn: " y "
    )

    assert_equal "WPA", area.workpl_cd
    assert_equal "A01", area.area_cd
    assert_equal "입고구역", area.area_nm
    assert_equal "설명", area.area_desc
    assert_equal "Y", area.use_yn
  end

  test "requires workplace code, area code and area name" do
    area = WmArea.new(workpl_cd: "", area_cd: "", area_nm: "", use_yn: "Y")

    assert_not area.valid?
    assert_includes area.errors[:workpl_cd], "can't be blank"
    assert_includes area.errors[:area_cd], "can't be blank"
    assert_includes area.errors[:area_nm], "can't be blank"
  end

  test "rejects invalid use_yn" do
    area = WmArea.new(
      workpl_cd: "WPA",
      area_cd: "A99",
      area_nm: "테스트",
      use_yn: "X"
    )

    assert_not area.valid?
    assert_includes area.errors[:use_yn], "is not included in the list"
  end

  test "rejects unknown workplace code" do
    area = WmArea.new(
      workpl_cd: "UNKNOWN",
      area_cd: "A01",
      area_nm: "미지정",
      use_yn: "Y"
    )

    assert_not area.valid?
    assert_includes area.errors[:workpl_cd], "does not exist"
  end
end
