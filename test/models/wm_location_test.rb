require "test_helper"

class WmLocationTest < ActiveSupport::TestCase
  setup do
    WmWorkplace.find_or_create_by!(workpl_cd: "WPA") do |workplace|
      workplace.workpl_nm = "Workplace A"
      workplace.use_yn = "Y"
    end

    WmArea.find_or_create_by!(workpl_cd: "WPA", area_cd: "A01") do |area|
      area.area_nm = "Area A"
      area.use_yn = "Y"
    end

    WmZone.find_or_create_by!(workpl_cd: "WPA", area_cd: "A01", zone_cd: "Z01") do |zone|
      zone.zone_nm = "Zone A"
      zone.use_yn = "Y"
    end
  end

  test "valid with required fields" do
    location = WmLocation.new(
      workpl_cd: "WPA",
      area_cd: "A01",
      zone_cd: "Z01",
      loc_cd: "L01",
      loc_nm: "Location A",
      use_yn: "Y"
    )

    assert location.valid?
  end

  test "normalizes code and text fields before validation" do
    location = WmLocation.create!(
      workpl_cd: " wpa ",
      area_cd: " a01 ",
      zone_cd: " z01 ",
      loc_cd: " l01 ",
      loc_nm: " Location A ",
      loc_class_cd: " storage ",
      loc_type_cd: " normal ",
      has_stock: " n ",
      use_yn: " y "
    )

    assert_equal "WPA", location.workpl_cd
    assert_equal "A01", location.area_cd
    assert_equal "Z01", location.zone_cd
    assert_equal "L01", location.loc_cd
    assert_equal "Location A", location.loc_nm
    assert_equal "STORAGE", location.loc_class_cd
    assert_equal "NORMAL", location.loc_type_cd
    assert_equal "N", location.has_stock
    assert_equal "Y", location.use_yn
  end

  test "requires key fields and name" do
    location = WmLocation.new(workpl_cd: "", area_cd: "", zone_cd: "", loc_cd: "", loc_nm: "", use_yn: "Y")

    assert_not location.valid?
    assert_includes location.errors[:workpl_cd], "can't be blank"
    assert_includes location.errors[:area_cd], "can't be blank"
    assert_includes location.errors[:zone_cd], "can't be blank"
    assert_includes location.errors[:loc_cd], "can't be blank"
    assert_includes location.errors[:loc_nm], "can't be blank"
  end

  test "rejects invalid code values" do
    location = WmLocation.new(
      workpl_cd: "WPA",
      area_cd: "A01",
      zone_cd: "Z01",
      loc_cd: "L99",
      loc_nm: "Invalid",
      loc_class_cd: "BAD",
      use_yn: "X"
    )

    assert_not location.valid?
    assert_includes location.errors[:loc_class_cd], "is not included in the list"
    assert_includes location.errors[:use_yn], "is not included in the list"
  end

  test "rejects negative numeric fields" do
    location = WmLocation.new(
      workpl_cd: "WPA",
      area_cd: "A01",
      zone_cd: "Z01",
      loc_cd: "L10",
      loc_nm: "Negative",
      width_len: -1,
      use_yn: "Y"
    )

    assert_not location.valid?
    assert_includes location.errors[:width_len], "must be greater than or equal to 0"
  end

  test "rejects unknown zone key" do
    location = WmLocation.new(
      workpl_cd: "WPA",
      area_cd: "A01",
      zone_cd: "UNKNOWN",
      loc_cd: "L01",
      loc_nm: "Missing Zone",
      use_yn: "Y"
    )

    assert_not location.valid?
    assert_includes location.errors[:zone_cd], "does not exist"
  end
end
