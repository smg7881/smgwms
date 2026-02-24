require "test_helper"

class Om::OrderManualCompletionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    post session_path, params: { email_address: "admin@example.com", password: "password" }
  end

  test "index responds to html" do
    get om_order_manual_completions_url
    assert_response :success
  end

  test "index json returns manual completion candidates only" do
    candidate = create_order!(
      ord_no: "OM-MANUAL-001",
      cust_cd: "CUST1",
      ord_stat_cd: "50",
      ord_type_cd: "10"
    )
    create_order!(
      ord_no: "OM-MANUAL-002",
      cust_cd: "CUST1",
      ord_stat_cd: "60",
      ord_type_cd: "10"
    )
    create_order!(
      ord_no: "OM-MANUAL-003",
      cust_cd: "CUST1",
      ord_stat_cd: "50",
      ord_type_cd: "30"
    )

    get om_order_manual_completions_url(format: :json), params: {
      q: {
        cust_cd: "CUST1",
        date_type: "create_time",
        start_date: (candidate.create_time.to_date - 1).to_s,
        end_date: (candidate.create_time.to_date + 1).to_s
      }
    }

    assert_response :success
    rows = JSON.parse(response.body)
    order_nos = rows.map { |row| row["ord_no"] }

    assert_includes order_nos, "OM-MANUAL-001"
    assert_not_includes order_nos, "OM-MANUAL-002"
    assert_not_includes order_nos, "OM-MANUAL-003"
  end

  test "details returns computed summary row" do
    order = create_order!(
      ord_no: "OM-MANUAL-DETAIL-001",
      ord_stat_cd: "50",
      ord_type_cd: "10",
      item_cd: "ITEM001",
      item_nm: "테스트아이템",
      ord_qty: 100,
      ord_wgt: 10,
      ord_vol: 5
    )

    OmWorkRoute.create!(ord_no: order.ord_no, work_route_no: "WR-001")
    OmWorkRouteResult.create!(
      ord_no: order.ord_no,
      work_route_no: "WR-001",
      rslt_qty: 30,
      rslt_wgt: 3,
      rslt_vol: 1
    )

    get details_om_order_manual_completion_url(order.ord_no, format: :json)
    assert_response :success

    rows = JSON.parse(response.body)
    assert_equal 1, rows.length
    assert_equal "ITEM001", rows.first["item_cd"]
    assert_equal 70.0, rows.first["rem_qty"]
  end

  test "complete updates selected orders" do
    order = create_order!(
      ord_no: "OM-MANUAL-COMPLETE-001",
      ord_stat_cd: "50",
      ord_type_cd: "10"
    )

    post complete_om_order_manual_completions_url, params: {
      order_nos: [ order.ord_no ],
      reason: "작업 완료 후 미자동완료건 수동처리"
    }, as: :json

    assert_response :success
    result = JSON.parse(response.body)
    assert result["success"]

    order.reload
    assert_equal "60", order.ord_stat_cd
    assert_equal "20", order.ord_cmpt_div_cd
    assert_not_nil order.ord_cmpt_dtm
    assert_equal "작업 완료 후 미자동완료건 수동처리", order.manl_cmpt_rsn
  end

  test "complete validates reason" do
    order = create_order!(
      ord_no: "OM-MANUAL-COMPLETE-002",
      ord_stat_cd: "50",
      ord_type_cd: "10"
    )

    post complete_om_order_manual_completions_url, params: {
      order_nos: [ order.ord_no ],
      reason: ""
    }, as: :json

    assert_response :unprocessable_entity
  end

  private
    def create_order!(attrs)
      defaults = {
        ord_no: "OM-#{SecureRandom.hex(4).upcase}",
        use_yn: "Y",
        ord_stat_cd: "50",
        ord_type_cd: "10",
        create_time: Time.current
      }
      OmOrder.create!(defaults.merge(attrs))
    end
end
