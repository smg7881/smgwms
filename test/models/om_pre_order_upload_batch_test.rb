require "test_helper"

class OmPreOrderUploadBatchTest < ActiveSupport::TestCase
  test "requires upload_batch_no" do
    batch = OmPreOrderUploadBatch.new(
      file_nm: "sample.xlsx",
      upload_stat_cd: "SUCCESS",
      error_cnt: 0,
      use_yn: "Y"
    )

    assert_not batch.valid?
    assert_includes batch.errors[:upload_batch_no], "can't be blank"
  end

  test "normalizes fields and defaults use_yn" do
    batch = OmPreOrderUploadBatch.create!(
      upload_batch_no: " batch001 ",
      file_nm: " sample.xlsx ",
      upload_stat_cd: " success ",
      cust_cd: " c000001 ",
      cust_nm: " 고객A ",
      error_cnt: 0,
      use_yn: ""
    )

    assert_equal "BATCH001", batch.upload_batch_no
    assert_equal "sample.xlsx", batch.file_nm
    assert_equal "SUCCESS", batch.upload_stat_cd
    assert_equal "C000001", batch.cust_cd
    assert_equal "고객A", batch.cust_nm
    assert_equal "Y", batch.use_yn
  end
end
