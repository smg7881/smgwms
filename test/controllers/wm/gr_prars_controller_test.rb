require "test_helper"
require "securerandom"

class Wm::GrPrarsControllerTest < ActionDispatch::IntegrationTest
  setup do
    post session_path, params: { email_address: "admin@example.com", password: "password" }
  end

  test "index json returns master rows" do
    gr_prar = create_gr_prar_with_detail

    get wm_gr_prars_url(format: :json), params: { q: { workpl_cd: gr_prar.workpl_cd } }
    assert_response :success

    rows = JSON.parse(response.body)
    assert_equal gr_prar.gr_prar_no, rows.first["gr_prar_no"]
  end

  test "nested details route returns detail rows" do
    gr_prar = create_gr_prar_with_detail

    get wm_gr_prar_details_url(gr_prar.gr_prar_no, format: :json)
    assert_response :success

    rows = JSON.parse(response.body)
    assert_equal 1, rows.size
    assert_equal 1, rows.first["lineno"]
    assert_equal gr_prar.gr_prar_no, rows.first["gr_prar_no"]
  end

  test "batch_save updates master editable fields" do
    gr_prar = create_gr_prar_with_detail

    post batch_save_wm_gr_prars_url, params: {
      rowsToInsert: [],
      rowsToUpdate: [
        {
          gr_prar_no: gr_prar.gr_prar_no,
          car_no: "12가3456",
          driver_telno: "010-1111-2222",
          rmk: "master update"
        }
      ],
      rowsToDelete: []
    }, as: :json

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal true, body["success"]
    assert_equal 1, body.dig("data", "updated")

    gr_prar.reload
    assert_equal "12가3456", gr_prar.car_no
    assert_equal "010-1111-2222", gr_prar.driver_telno
    assert_equal "master update", gr_prar.rmk
  end

  test "batch_save updates detail editable fields" do
    gr_prar = create_gr_prar_with_detail

    post batch_save_wm_gr_prar_details_url(gr_prar.gr_prar_no), params: {
      rowsToInsert: [],
      rowsToUpdate: [
        {
          lineno: 1,
          gr_loc_cd: "LOC01",
          gr_qty: 2.5,
          rmk: "detail update",
          stock_attr_col01: "LOT-A"
        }
      ],
      rowsToDelete: []
    }, as: :json

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal true, body["success"]
    assert_equal 1, body.dig("data", "updated")

    detail = gr_prar.details.find_by!(lineno: 1)
    assert_equal "LOC01", detail.gr_loc_cd
    assert_equal 2.5, detail.gr_qty.to_f
    assert_equal "detail update", detail.rmk
    assert_equal "LOT-A", detail.stock_attr_col01
  end

  test "generate creates inbound plan and details" do
    assert_difference("Wm::GrPrar.count", 1) do
      assert_difference("Wm::GrPrarDtl.count", 3) do
        post generate_wm_gr_prars_url, params: {
          workpl_cd: "WP01",
          cust_cd: "CUST01",
          gr_type_cd: "10",
          prar_ymd: "2026-03-08"
        }, as: :json
      end
    end

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal true, body["success"]
    assert_equal "입고예정이 생성되었습니다.", body["message"]

    created_no = body.dig("data", "gr_prar_no")
    assert created_no.present?

    created = Wm::GrPrar.find(created_no)
    assert_equal "WP01", created.workpl_cd
    assert_equal "CUST01", created.cust_cd
    assert_equal Wm::GrPrar::GR_STAT_PENDING, created.gr_stat_cd
    assert_equal "20260308", created.prar_ymd
    assert_equal 3, created.details.count
  end

  test "save_gr returns standard batch data and updates stocks" do
    gr_prar = create_gr_prar_with_detail

    post save_gr_wm_gr_prar_url(gr_prar.gr_prar_no), params: {
      rows: [
        {
          lineno: 1,
          gr_loc_cd: "STAGE01",
          gr_qty: 3,
          rmk: "save_gr update",
          stock_attr_col01: "LOT-001"
        }
      ]
    }, as: :json

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal true, body["success"]
    assert_equal 0, body.dig("data", "inserted")
    assert_equal 0, body.dig("data", "deleted")
    assert_operator body.dig("data", "updated"), :>=, 1

    detail = gr_prar.details.find_by!(lineno: 1)
    assert_equal "STAGE01", detail.gr_loc_cd
    assert_equal 3.0, detail.gr_qty.to_f
    assert_equal 3.0, detail.gr_rslt_qty.to_f
    assert_equal Wm::GrPrar::GR_STAT_PROCESSED, detail.gr_stat_cd

    assert Wm::ExceRslt.exists?(
      op_rslt_mngt_no: gr_prar.gr_prar_no,
      op_rslt_mngt_no_seq: 1,
      exce_rslt_type: Wm::ExceRslt::EXCE_RSLT_TYPE_DP
    )
  end

  private
    def create_gr_prar_with_detail
      gr_prar_no = "GRT#{SecureRandom.alphanumeric(8).upcase}"
      gr_prar = Wm::GrPrar.create!(
        gr_prar_no: gr_prar_no,
        workpl_cd: "WP01",
        corp_cd: "DEFAULT",
        cust_cd: "CUST01",
        gr_type_cd: "10",
        ord_reason_cd: "01",
        gr_stat_cd: Wm::GrPrar::GR_STAT_PENDING,
        prar_ymd: "20260306",
        ord_no: "ORD-#{SecureRandom.alphanumeric(6).upcase}",
        dptar_type_cd: "10",
        dptar_cd: "DPT01"
      )

      Wm::GrPrarDtl.create!(
        gr_prar_no: gr_prar.gr_prar_no,
        lineno: 1,
        item_cd: "ITEM01",
        item_nm: "TEST ITEM",
        unit_cd: "EA",
        gr_prar_qty: 10,
        gr_qty: 0,
        gr_rslt_qty: 0,
        gr_stat_cd: Wm::GrPrar::GR_STAT_PENDING
      )

      gr_prar
    end
end
