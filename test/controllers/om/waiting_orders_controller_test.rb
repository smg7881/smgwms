require "test_helper"

class Om::WaitingOrdersControllerTest < ActionDispatch::IntegrationTest
  setup do
    post session_path, params: { email_address: "admin@example.com", password: "password" }
  end

  test "index responds to html" do
    get om_waiting_orders_url
    assert_response :success
  end

  test "index json returns waiting orders only" do
    waiting = create_order!(
      ord_no: "OM-WAIT-001",
      work_stat_cd: "WAITING",
      create_time: Time.current
    )
    create_order!(
      ord_no: "OM-WAIT-002",
      work_stat_cd: "DONE",
      create_time: Time.current
    )

    get om_waiting_orders_url(format: :json), params: {
      q: {
        cust_cd: waiting.cust_cd,
        date_type: "CREATE_TIME",
        start_date: Date.current.to_s,
        end_date: Date.current.to_s
      }
    }

    assert_response :success
    rows = JSON.parse(response.body)
    order_nos = rows.map { |row| row["ord_no"] }

    assert_includes order_nos, "OM-WAIT-001"
    assert_not_includes order_nos, "OM-WAIT-002"
  end

  test "details returns computed row" do
    order = create_order!(
      ord_no: "OM-WAIT-DETAIL-001",
      item_cd: "ITEM01",
      item_nm: "테스트아이템",
      ord_qty: 100,
      ord_wgt: 20,
      ord_vol: 5
    )

    route = OmWorkRoute.create!(ord_no: order.ord_no, work_route_no: "WR-DETAIL-001")
    OmWorkRouteResult.create!(
      work_route_no: route.work_route_no,
      ord_no: order.ord_no,
      rslt_qty: 30,
      rslt_wgt: 4,
      rslt_vol: 1
    )

    get details_om_waiting_order_url(order.ord_no, format: :json)
    assert_response :success

    rows = JSON.parse(response.body)
    assert_equal 1, rows.length
    assert_equal "ITEM01", rows.first["item_cd"]
    assert_equal 70.0, rows.first["balance_qty"]
  end

  test "batch_save updates distribution result" do
    order = create_order!(
      ord_no: "OM-WAIT-SAVE-001",
      ord_qty: 100,
      ord_wgt: 10,
      ord_vol: 3
    )

    route = OmWorkRoute.create!(ord_no: order.ord_no, work_route_no: "WR-SAVE-001")
    OmWorkRouteResult.create!(
      work_route_no: route.work_route_no,
      ord_no: order.ord_no,
      rslt_qty: 20,
      rslt_wgt: 2,
      rslt_vol: 1
    )

    post batch_save_om_waiting_order_url(order.ord_no), params: {
      rowsToInsert: [],
      rowsToDelete: [],
      rowsToUpdate: [
        {
          ord_no: order.ord_no,
          seq: 1,
          item_cd: order.item_cd,
          div_qty: 10,
          div_wgt: 1,
          div_vol: 0.5
        }
      ]
    }, as: :json

    assert_response :success
    result = JSON.parse(response.body)
    assert result["success"]
    assert_equal 1, result["data"]["updated"]

    row = OmWorkRouteResult.find_by!(work_route_no: route.work_route_no, ord_no: order.ord_no)
    assert_equal 30.0, row.rslt_qty.to_f
    assert_equal 3.0, row.rslt_wgt.to_f
    assert_equal 1.5, row.rslt_vol.to_f
  end

  test "batch_save rejects over-balance distribution" do
    order = create_order!(
      ord_no: "OM-WAIT-SAVE-002",
      ord_qty: 10,
      ord_wgt: 5,
      ord_vol: 2
    )

    route = OmWorkRoute.create!(ord_no: order.ord_no, work_route_no: "WR-SAVE-002")
    OmWorkRouteResult.create!(
      work_route_no: route.work_route_no,
      ord_no: order.ord_no,
      rslt_qty: 9,
      rslt_wgt: 4,
      rslt_vol: 1.9
    )

    post batch_save_om_waiting_order_url(order.ord_no), params: {
      rowsToInsert: [],
      rowsToDelete: [],
      rowsToUpdate: [
        {
          ord_no: order.ord_no,
          seq: 1,
          item_cd: order.item_cd,
          div_qty: 2,
          div_wgt: 2,
          div_vol: 1
        }
      ]
    }, as: :json

    assert_response :unprocessable_entity
    result = JSON.parse(response.body)
    assert_equal false, result["success"]
  end

  private
    def create_order!(attrs)
      defaults = {
        ord_no: "OM-#{SecureRandom.hex(4).upcase}",
        use_yn: "Y",
        cust_cd: "CUST01",
        cust_nm: "테스트고객",
        item_cd: "ITEM01",
        item_nm: "테스트아이템",
        work_stat_cd: "WAITING",
        create_time: Time.current,
        aptd_req_ymd: Date.current
      }

      OmOrder.create!(defaults.merge(attrs))
    end
end
