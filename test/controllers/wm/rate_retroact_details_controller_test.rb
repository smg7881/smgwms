require "test_helper"

class Wm::RateRetroactDetailsControllerTest < ActionDispatch::IntegrationTest
  setup do
    post session_path, params: { email_address: "admin@example.com", password: "password" }

    @master = Wm::SellFeeRtMng.create!(
      wrhs_exca_fee_rt_no: "S20260305001000111",
      corp_cd: "DEFAULT",
      work_pl_cd: "WP01",
      sell_buy_sctn_cd: "10",
      ctrt_cprtco_cd: "CUST01",
      sell_buy_attr_cd: "ATTR01",
      sell_dept_cd: "S01",
      sell_item_type: "A",
      sell_item_cd: "ITEM01",
      sell_unit_clas_cd: "10",
      sell_unit_cd: "EA",
      use_yn: "Y",
      auto_yn: "N"
    )
  end

  test "detail batch_save insert, update, delete works" do
    post batch_save_wm_rate_retroact_details_url(rate_retroact_id: @master.wrhs_exca_fee_rt_no), params: {
      ref_fee_rt_no: @master.wrhs_exca_fee_rt_no,
      ref_fee_rt_lineno: 1,
      rowsToInsert: [
        {
          exce_rslt_no: "ER_RATE_001",
          rslt_std_ymd: "20260305",
          op_rslt_mngt_no: "OP0001",
          lineno: 1,
          rslt_qty: 5,
          aply_uprice: 1000,
          rslt_amt: 5000,
          cur_cd: "KRW",
          rtac_uprice: 1200,
          rtac_amt: 6000,
          uprice_diff: 200,
          amt_diff: 1000
        }
      ],
      rowsToUpdate: [],
      rowsToDelete: []
    }, as: :json

    assert_response :success
    insert_body = JSON.parse(response.body)
    assert_equal true, insert_body["success"]
    assert_equal 1, insert_body.dig("data", "inserted")

    history = Wm::RateRetroactHistory.find_by(exce_rslt_no: "ER_RATE_001")
    assert_not_nil history
    assert_equal "C", history.prcs_sctn_cd
    assert_equal "1200.0", history.rtac_uprice.to_s

    post batch_save_wm_rate_retroact_details_url(rate_retroact_id: @master.wrhs_exca_fee_rt_no), params: {
      ref_fee_rt_no: @master.wrhs_exca_fee_rt_no,
      ref_fee_rt_lineno: 1,
      rowsToInsert: [],
      rowsToUpdate: [
        {
          exce_rslt_no: "ER_RATE_001",
          rslt_std_ymd: "20260305",
          op_rslt_mngt_no: "OP0001",
          lineno: 1,
          rslt_qty: 5,
          aply_uprice: 1000,
          rslt_amt: 5000,
          cur_cd: "KRW",
          rtac_uprice: 1300,
          rtac_amt: 6500,
          uprice_diff: 300,
          amt_diff: 1500
        }
      ],
      rowsToDelete: []
    }, as: :json

    assert_response :success
    update_body = JSON.parse(response.body)
    assert_equal true, update_body["success"]
    assert_equal 1, update_body.dig("data", "updated")
    assert_equal "U", history.reload.prcs_sctn_cd
    assert_equal "1300.0", history.rtac_uprice.to_s

    post batch_save_wm_rate_retroact_details_url(rate_retroact_id: @master.wrhs_exca_fee_rt_no), params: {
      rowsToInsert: [],
      rowsToUpdate: [],
      rowsToDelete: [ "ER_RATE_001" ]
    }, as: :json

    assert_response :success
    delete_body = JSON.parse(response.body)
    assert_equal true, delete_body["success"]
    assert_equal 1, delete_body.dig("data", "deleted")
    assert_nil Wm::RateRetroactHistory.find_by(exce_rslt_no: "ER_RATE_001")
  end
end
