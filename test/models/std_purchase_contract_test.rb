require "test_helper"

class StdPurchaseContractTest < ActiveSupport::TestCase
  test "generates purchase contract number and normalizes fields" do
    StdPurchaseContract.delete_all

    row = StdPurchaseContract.create!(
      corp_cd: " corp01 ",
      bzac_cd: " bz001 ",
      pur_ctrt_nm: "  테스트 계약  ",
      bizman_no: "123-45-67890",
      ctrt_sctn_cd: " general ",
      ctrt_kind_cd: " normal ",
      loan_limt_over_yn_cd: "",
      dcsn_yn_cd: "",
      use_yn_cd: ""
    )

    assert_equal "PC00000001", row.pur_ctrt_no
    assert_equal "CORP01", row.corp_cd
    assert_equal "BZ001", row.bzac_cd
    assert_equal "테스트 계약", row.pur_ctrt_nm
    assert_equal "1234567890", row.bizman_no
    assert_equal "GENERAL", row.ctrt_sctn_cd
    assert_equal "NORMAL", row.ctrt_kind_cd
    assert_equal "N", row.loan_limt_over_yn_cd
    assert_equal "N", row.dcsn_yn_cd
    assert_equal "Y", row.use_yn_cd
  end
end
