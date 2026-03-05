require "test_helper"

class Wm::SellFeeRtMngsControllerTest < ActionDispatch::IntegrationTest
  setup do
    post session_path, params: { email_address: "admin@example.com", password: "password" }
  end

  test "batch_save creates master and detail together" do
    post batch_save_wm_sell_fee_rt_mngs_url, params: {
      rowsToInsert: [
        {
          client_temp_id: "TMP_A",
          work_pl_cd: "WP01",
          ctrt_cprtco_cd: "CUST01",
          sell_buy_attr_cd: "ATTR01",
          sell_dept_cd: "S01",
          sell_item_type: "A",
          sell_item_cd: "ITEM01",
          sell_unit_clas_cd: "10",
          sell_unit_cd: "EA",
          use_yn: "Y",
          auto_yn: "N",
          rmk: "신규"
        }
      ],
      rowsToUpdate: [],
      rowsToDelete: [],
      detailOperations: {
        master_client_temp_id: "TMP_A",
        rowsToInsert: [
          {
            dcsn_yn: "N",
            aply_strt_ymd: "2026-01-01",
            aply_end_ymd: "2026-12-31",
            aply_uprice: 1000,
            cur_cd: "KRW",
            std_work_qty: 1,
            aply_strt_qty: 1,
            aply_end_qty: 9999,
            rmk: "상세"
          }
        ],
        rowsToUpdate: [],
        rowsToDelete: []
      }
    }, as: :json

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal true, body["success"]
    assert_equal 1, body.dig("data", "master", "inserted")
    assert_equal 1, body.dig("data", "detail", "inserted")

    created_key = body["selected_master_key"]
    assert created_key.present?
    assert Wm::SellFeeRtMng.exists?(wrhs_exca_fee_rt_no: created_key)
    assert_equal 1, Wm::SellFeeRtMngDtl.where(wrhs_exca_fee_rt_no: created_key).count
  end

  test "batch_save rejects new master without detail rows" do
    post batch_save_wm_sell_fee_rt_mngs_url, params: {
      rowsToInsert: [
        {
          client_temp_id: "TMP_B",
          work_pl_cd: "WP01",
          ctrt_cprtco_cd: "CUST01",
          sell_buy_attr_cd: "ATTR01",
          sell_dept_cd: "S01",
          sell_item_type: "A",
          sell_item_cd: "ITEM01",
          sell_unit_clas_cd: "10",
          sell_unit_cd: "EA",
          use_yn: "Y",
          auto_yn: "N"
        }
      ],
      rowsToUpdate: [],
      rowsToDelete: [],
      detailOperations: {
        master_client_temp_id: "TMP_B",
        rowsToInsert: [],
        rowsToUpdate: [],
        rowsToDelete: []
      }
    }, as: :json

    assert_response :unprocessable_entity
    body = JSON.parse(response.body)
    assert_equal false, body["success"]
    assert_includes body["errors"], "요율상세를 등록하시기 바랍니다."
  end

  test "batch_save updates master and detail together" do
    master = Wm::SellFeeRtMng.create!(
      wrhs_exca_fee_rt_no: "S20260101000000111",
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
    detail = Wm::SellFeeRtMngDtl.create!(
      wrhs_exca_fee_rt_no: master.wrhs_exca_fee_rt_no,
      lineno: 1,
      dcsn_yn: "N",
      aply_strt_ymd: "20260101",
      aply_end_ymd: "20261231",
      aply_uprice: 1000,
      cur_cd: "KRW",
      std_work_qty: 1
    )

    post batch_save_wm_sell_fee_rt_mngs_url, params: {
      rowsToInsert: [],
      rowsToUpdate: [
        {
          wrhs_exca_fee_rt_no: master.wrhs_exca_fee_rt_no,
          work_pl_cd: "WP01",
          ctrt_cprtco_cd: "CUST01",
          sell_buy_attr_cd: "ATTR01",
          sell_dept_cd: "S02",
          sell_item_type: "B",
          sell_item_cd: "ITEM02",
          sell_unit_clas_cd: "20",
          sell_unit_cd: "BOX",
          use_yn: "N",
          auto_yn: "Y",
          rmk: "수정"
        }
      ],
      rowsToDelete: [],
      detailOperations: {
        master_key: master.wrhs_exca_fee_rt_no,
        rowsToInsert: [],
        rowsToUpdate: [
          {
            lineno: detail.lineno,
            dcsn_yn: "Y",
            aply_strt_ymd: "2026-02-01",
            aply_end_ymd: "2026-12-31",
            aply_uprice: 2500,
            cur_cd: "USD",
            std_work_qty: 2,
            aply_strt_qty: 2,
            aply_end_qty: 5000,
            rmk: "상세수정"
          }
        ],
        rowsToDelete: []
      }
    }, as: :json

    assert_response :success
    assert_equal "S02", master.reload.sell_dept_cd
    assert_equal "ITEM02", master.sell_item_cd
    assert_equal "N", master.use_yn
    assert_equal "2500.0", detail.reload.aply_uprice.to_s
    assert_equal "USD", detail.cur_cd
    assert_equal "20260201", detail.aply_strt_ymd
  end
end
