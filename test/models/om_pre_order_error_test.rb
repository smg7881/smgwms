require "test_helper"

class OmPreOrderErrorTest < ActiveSupport::TestCase
  test "requires upload_batch_no and line_no" do
    row = OmPreOrderError.new(
      err_type_cd: "VALIDATION",
      err_msg: "수량은 필수입니다.",
      resolved_yn: "N",
      use_yn: "Y"
    )

    assert_not row.valid?
    assert_includes row.errors[:upload_batch_no], "can't be blank"
    assert_includes row.errors[:line_no], "can't be blank"
  end

  test "normalizes fields and defaults flags" do
    row = OmPreOrderError.create!(
      upload_batch_no: " batch001 ",
      line_no: 3,
      err_type_cd: " validation ",
      err_msg: " 오류 ",
      cust_ord_no: " co001 ",
      item_cd: " item001 ",
      resolved_yn: "",
      use_yn: ""
    )

    assert_equal "BATCH001", row.upload_batch_no
    assert_equal "VALIDATION", row.err_type_cd
    assert_equal "오류", row.err_msg
    assert_equal "CO001", row.cust_ord_no
    assert_equal "ITEM001", row.item_cd
    assert_equal "N", row.resolved_yn
    assert_equal "Y", row.use_yn
  end
end
