require "test_helper"

class OmCustomerOrderOfficerTest < ActiveSupport::TestCase
  test "requires required fields" do
    row = OmCustomerOrderOfficer.new(
      cust_cd: "C000001",
      exp_imp_dom_sctn_cd: "DOMESTIC",
      cust_ofcr_nm: "홍길동",
      cust_ofcr_tel_no: "010-1111-2222",
      use_yn: "Y"
    )

    assert_not row.valid?
    assert_includes row.errors[:ord_chrg_dept_cd], "can't be blank"
  end

  test "normalizes fields and defaults use_yn" do
    row = OmCustomerOrderOfficer.create!(
      ord_chrg_dept_cd: " d001 ",
      ord_chrg_dept_nm: " 영업1팀 ",
      cust_cd: " c000001 ",
      cust_nm: " 고객A ",
      exp_imp_dom_sctn_cd: " domestic ",
      cust_ofcr_nm: " 홍길동 ",
      cust_ofcr_tel_no: " 010-1234-5678 ",
      cust_ofcr_mbp_no: " 010-9876-5432 ",
      use_yn: ""
    )

    assert_equal "D001", row.ord_chrg_dept_cd
    assert_equal "영업1팀", row.ord_chrg_dept_nm
    assert_equal "C000001", row.cust_cd
    assert_equal "고객A", row.cust_nm
    assert_equal "DOMESTIC", row.exp_imp_dom_sctn_cd
    assert_equal "홍길동", row.cust_ofcr_nm
    assert_equal "010-1234-5678", row.cust_ofcr_tel_no
    assert_equal "010-9876-5432", row.cust_ofcr_mbp_no
    assert_equal "Y", row.use_yn
  end
end
