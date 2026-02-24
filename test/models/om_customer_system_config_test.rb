require "test_helper"

class OmCustomerSystemConfigTest < ActiveSupport::TestCase
  test "requires customer code when setup unit is CUSTOMER" do
    row = OmCustomerSystemConfig.new(
      setup_unit_cd: "CUSTOMER",
      lclas_cd: "TEST_LCLAS",
      mclas_cd: "TEST_MCLAS",
      sclas_cd: "TEST_SCLAS",
      setup_sctn_cd: "VALIDATE",
      use_yn: "Y"
    )

    assert_not row.valid?
    assert_includes row.errors[:cust_cd], "can't be blank"
  end

  test "normalizes fields and clears customer code for system rows" do
    row = OmCustomerSystemConfig.create!(
      setup_unit_cd: "system ",
      cust_cd: "c000001",
      lclas_cd: " test_lclas ",
      mclas_cd: " test_mclas ",
      sclas_cd: " test_sclas ",
      setup_sctn_cd: " validate ",
      module_nm: " 품명 ",
      setup_value: " y ",
      use_yn: ""
    )

    assert_equal "SYSTEM", row.setup_unit_cd
    assert_equal "", row.cust_cd
    assert_equal "TEST_LCLAS", row.lclas_cd
    assert_equal "TEST_MCLAS", row.mclas_cd
    assert_equal "TEST_SCLAS", row.sclas_cd
    assert_equal "VALIDATE", row.setup_sctn_cd
    assert_equal "품명", row.module_nm
    assert_equal "y", row.setup_value
    assert_equal "Y", row.use_yn
  end
end
