require "test_helper"

class StdBzacMstTest < ActiveSupport::TestCase
  def base_attributes
    {
      bzac_nm: "Alpha Client",
      mngt_corp_cd: "corp01",
      bizman_no: "123-45-67890",
      bzac_sctn_grp_cd: "customer",
      bzac_sctn_cd: "domestic",
      bzac_kind_cd: "corp",
      ctry_cd: "kr",
      tpl_logis_yn_cd: "n",
      if_yn_cd: "n",
      branch_yn_cd: "n",
      sell_bzac_yn_cd: "y",
      pur_bzac_yn_cd: "y",
      elec_taxbill_yn_cd: "n",
      rpt_sales_emp_cd: "emp01",
      aply_strt_day_cd: Date.current,
      use_yn_cd: "y"
    }
  end

  test "valid with required fields and auto code assignment" do
    client = StdBzacMst.new(base_attributes)

    assert client.valid?
    client.save!
    assert_match(/\A\d{8}\z/, client.bzac_cd)
  end

  test "normalizes fields before validation" do
    client = StdBzacMst.create!(
      base_attributes.merge(
        bzac_cd: " ab01 ",
        bzac_sctn_grp_cd: " customer ",
        bzac_sctn_cd: " domestic ",
        bizman_no: "123-45-67890",
        use_yn_cd: " y "
      )
    )

    assert_equal "AB01", client.bzac_cd
    assert_equal "CUSTOMER", client.bzac_sctn_grp_cd
    assert_equal "DOMESTIC", client.bzac_sctn_cd
    assert_equal "1234567890", client.bizman_no
    assert_equal "Y", client.use_yn_cd
  end

  test "requires unique business number when representative client is blank" do
    StdBzacMst.create!(base_attributes.merge(bzac_cd: "CL000001", bizman_no: "1234567890"))

    duplicate = StdBzacMst.new(base_attributes.merge(bzac_cd: "CL000002", bizman_no: "1234567890"))

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:bizman_no], "must be unique when representative client is blank"
  end

  test "allows duplicated business number when representative client exists" do
    StdBzacMst.create!(base_attributes.merge(bzac_cd: "CL000001", bizman_no: "1234567890"))

    follower = StdBzacMst.new(
      base_attributes.merge(
        bzac_cd: "CL000002",
        bizman_no: "1234567890",
        rpt_bzac_cd: "CL000001"
      )
    )

    assert follower.valid?
  end
end
