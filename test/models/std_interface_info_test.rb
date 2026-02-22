require "test_helper"

class StdInterfaceInfoTest < ActiveSupport::TestCase
  test "assigns interface code automatically" do
    row = StdInterfaceInfo.create!(
      corp_cd: "CP01",
      if_meth_cd: "API",
      if_sctn_cd: "INTERNAL",
      if_nm_cd: "Auto Code",
      send_sys_cd: "WMS",
      rcv_sys_cd: "ERP",
      use_yn_cd: "Y"
    )

    assert_match(/\AV\d{10}\z/, row.if_cd)
  end

  test "validates internal interface required fields" do
    row = StdInterfaceInfo.new(
      corp_cd: "CP01",
      if_cd: "V0000000099",
      if_meth_cd: "API",
      if_sctn_cd: "INTERNAL",
      if_nm_cd: "Invalid",
      use_yn_cd: "Y"
    )

    assert_not row.valid?
    assert_includes row.errors[:send_sys_cd], "can't be blank"
    assert_includes row.errors[:rcv_sys_cd], "can't be blank"
  end

  test "validates external interface required fields" do
    row = StdInterfaceInfo.new(
      corp_cd: "CP01",
      if_cd: "V0000000100",
      if_meth_cd: "FILE",
      if_sctn_cd: "EXTERNAL",
      if_nm_cd: "Invalid",
      use_yn_cd: "Y"
    )

    assert_not row.valid?
    assert_includes row.errors[:if_bzac_cd], "can't be blank"
    assert_includes row.errors[:bzac_sys_nm_cd], "can't be blank"
  end
end
