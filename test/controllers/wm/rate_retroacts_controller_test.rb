require "test_helper"

class Wm::RateRetroactsControllerTest < ActionDispatch::IntegrationTest
  setup do
    post session_path, params: { email_address: "admin@example.com", password: "password" }
  end

  test "index redirects with default query" do
    get wm_rate_retroacts_url

    assert_response :redirect
    assert_includes response.location, "q%5Bsell_buy_sctn_cd%5D=10"
  end

  test "index renders html when query exists" do
    get wm_rate_retroacts_url, params: { q: { sell_buy_sctn_cd: "10", use_yn: "Y" } }

    assert_response :success
  end

  test "batch_save master update works for existing rate" do
    master = Wm::SellFeeRtMng.create!(
      wrhs_exca_fee_rt_no: "S20260305000900111",
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

    post batch_save_wm_rate_retroacts_url, params: {
      rowsToInsert: [],
      rowsToUpdate: [
        {
          wrhs_exca_fee_rt_no: master.wrhs_exca_fee_rt_no,
          rtac_feert: 1500
        }
      ],
      rowsToDelete: []
    }, as: :json

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal true, body["success"]
    assert_equal 1, body.dig("data", "updated")
  end

  test "batch_save master insert is rejected" do
    post batch_save_wm_rate_retroacts_url, params: {
      rowsToInsert: [
        {
          wrhs_exca_fee_rt_no: "NEW001",
          rtac_feert: 1000
        }
      ],
      rowsToUpdate: [],
      rowsToDelete: []
    }, as: :json

    assert_response :unprocessable_entity
    body = JSON.parse(response.body)
    assert_equal false, body["success"]
  end

  test "apply_retro_rates returns calculated values" do
    post apply_retro_rates_wm_rate_retroacts_url, params: {
      retro_uprice: 1500,
      retro_cur_cd: "KRW",
      rows: [
        { exce_rslt_no: "ER001", rslt_qty: 10, aply_uprice: 1200 }
      ]
    }, as: :json

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal true, body["success"]

    row = body.dig("data", "rows", 0)
    assert_equal "ER001", row["exce_rslt_no"]
    assert_equal 15000.0, row["rtac_amt"]
    assert_equal 3000.0, row["amt_diff"]
  end

  test "process_retroacts inserts and updates history" do
    Wm::ExceRslt.create!(
      exce_rslt_no: "ER_TEST_001",
      exce_rslt_type: Wm::ExceRslt::EXCE_RSLT_TYPE_DP,
      exce_rslt_ymd: "20260305",
      workpl_cd: "WP01",
      op_rslt_mngt_no: "OP0001",
      op_rslt_mngt_no_seq: 1,
      rslt_qty: 5
    )

    post process_retroacts_wm_rate_retroacts_url, params: {
      work_pl_cd: "WP01",
      sell_buy_sctn_cd: "10",
      bzac_cd: "CUST01",
      sell_buy_attr_cd: "ATTR01",
      ref_fee_rt_no: "S202603050001",
      ref_fee_rt_lineno: 1,
      rows: [
        {
          exce_rslt_no: "ER_TEST_001",
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
      ]
    }, as: :json

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 1, body.dig("data", "inserted")
    assert_equal 0, body.dig("data", "updated")

    history = Wm::RateRetroactHistory.find_by(exce_rslt_no: "ER_TEST_001")
    assert_not_nil history
    assert_equal "C", history.prcs_sctn_cd
    assert_equal "RTAC", history.rtac_proc_stat_cd

    post process_retroacts_wm_rate_retroacts_url, params: {
      work_pl_cd: "WP01",
      sell_buy_sctn_cd: "10",
      bzac_cd: "CUST01",
      sell_buy_attr_cd: "ATTR01",
      ref_fee_rt_no: "S202603050001",
      ref_fee_rt_lineno: 1,
      rows: [
        {
          exce_rslt_no: "ER_TEST_001",
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
      ]
    }, as: :json

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 0, body.dig("data", "inserted")
    assert_equal 1, body.dig("data", "updated")

    assert_equal "U", history.reload.prcs_sctn_cd
    assert_equal "1300.0", history.rtac_uprice.to_s
  end

  test "fee_rate popup json works" do
    get search_popup_url(type: "fee_rate", format: :json)

    assert_response :success
  end

  test "fee_rate popup html works" do
    get search_popup_url(type: "fee_rate")

    assert_response :success
  end
end
