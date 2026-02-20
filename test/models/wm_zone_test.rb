require "test_helper"

class WmZoneTest < ActiveSupport::TestCase
  setup do
    WmLocation.where(workpl_cd: "WPA").delete_all
    WmZone.where(workpl_cd: "WPA").delete_all
    WmArea.where(workpl_cd: "WPA").delete_all
    WmWorkplace.where(workpl_cd: "WPA").delete_all

    WmWorkplace.create!(workpl_cd: "WPA", workpl_nm: "Workplace A", use_yn: "Y")
    WmArea.create!(workpl_cd: "WPA", area_cd: "A01", area_nm: "Area A", use_yn: "Y")
  end

  test "valid with required fields" do
    zone = WmZone.new(
      workpl_cd: "WPA",
      area_cd: "A01",
      zone_cd: "Z01",
      zone_nm: "Zone A",
      use_yn: "Y"
    )

    assert zone.valid?
  end

  test "normalizes code and text fields before validation" do
    zone = WmZone.create!(
      workpl_cd: " wpa ",
      area_cd: " a01 ",
      zone_cd: " z01 ",
      zone_nm: " Zone A ",
      zone_desc: " desc ",
      use_yn: " y "
    )

    assert_equal "WPA", zone.workpl_cd
    assert_equal "A01", zone.area_cd
    assert_equal "Z01", zone.zone_cd
    assert_equal "Zone A", zone.zone_nm
    assert_equal "desc", zone.zone_desc
    assert_equal "Y", zone.use_yn
  end

  test "requires zone keys and name" do
    zone = WmZone.new(workpl_cd: "", area_cd: "", zone_cd: "", zone_nm: "", use_yn: "Y")

    assert_not zone.valid?
    assert_includes zone.errors[:workpl_cd], "can't be blank"
    assert_includes zone.errors[:area_cd], "can't be blank"
    assert_includes zone.errors[:zone_cd], "can't be blank"
    assert_includes zone.errors[:zone_nm], "can't be blank"
  end

  test "rejects invalid use_yn" do
    zone = WmZone.new(
      workpl_cd: "WPA",
      area_cd: "A01",
      zone_cd: "Z99",
      zone_nm: "Test",
      use_yn: "X"
    )

    assert_not zone.valid?
    assert_includes zone.errors[:use_yn], "is not included in the list"
  end

  test "rejects unknown area key" do
    zone = WmZone.new(
      workpl_cd: "WPA",
      area_cd: "UNKNOWN",
      zone_cd: "Z01",
      zone_nm: "Missing",
      use_yn: "Y"
    )

    assert_not zone.valid?
    assert_includes zone.errors[:area_cd], "does not exist"
  end
end
