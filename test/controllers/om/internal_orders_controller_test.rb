require "test_helper"

class Om::InternalOrdersControllerTest < ActionDispatch::IntegrationTest
  setup do
    post session_path, params: { email_address: "admin@example.com", password: "password" }
  end

  test "index responds to html" do
    get om_internal_orders_url
    assert_response :success
  end

  test "index json requires ord_no" do
    get om_internal_orders_url(format: :json)
    assert_response :unprocessable_entity
  end

  test "index json returns order by ord_no" do
    order = OmInternalOrder.create!(
      ord_stat_cd: "WAIT",
      wait_ord_internal_yn: "N",
      cancel_yn: "N"
    )

    get om_internal_orders_url(format: :json), params: { q: { ord_no: order.ord_no } }
    assert_response :success

    result = JSON.parse(response.body)
    assert result["success"]
    assert_equal order.ord_no, result["data"]["ord_no"]
  end

  test "index json returns not found for missing order" do
    get om_internal_orders_url(format: :json), params: { q: { ord_no: "NONEXISTENT" } }
    assert_response :not_found
  end

  test "create creates new internal order" do
    post om_internal_orders_url, params: {
      order: {
        ctrt_no: "CTR001",
        ord_type_cd: "NORMAL",
        bilg_cust_cd: "CUST001",
        ctrt_cust_cd: "CUST002",
        dpt_type_cd: "WORKPLACE",
        dpt_cd: "WP001",
        arv_type_cd: "CUSTOMER",
        arv_cd: "CV001",
        remk: "테스트 내부오더"
      },
      items: [
        { seq_no: 1, item_cd: "ITEM001", item_nm: "테스트아이템", ord_qty: 10, qty_unit_cd: "EA" },
        { seq_no: 2, item_cd: "ITEM002", item_nm: "테스트아이템2", ord_qty: 5, qty_unit_cd: "BOX" }
      ]
    }, as: :json

    assert_response :success
    result = JSON.parse(response.body)
    assert result["success"]
    assert result["data"]["ord_no"].present?
    assert_equal 2, result["data"]["items"].length
  end

  test "update modifies existing order and replaces items" do
    order = OmInternalOrder.create!(
      ord_stat_cd: "WAIT",
      wait_ord_internal_yn: "N",
      cancel_yn: "N",
      ctrt_no: "OLD_CTR"
    )
    order.items.create!(seq_no: 1, item_cd: "OLD_ITEM")

    patch om_internal_order_url(order), params: {
      order: { ctrt_no: "NEW_CTR", remk: "수정 테스트" },
      items: [
        { seq_no: 1, item_cd: "NEW_ITEM1", item_nm: "새아이템", ord_qty: 20 }
      ]
    }, as: :json

    assert_response :success
    result = JSON.parse(response.body)
    assert result["success"]
    assert_equal "NEW_CTR", result["data"]["ctrt_no"]
    assert_equal 1, result["data"]["items"].length
    assert_equal "NEW_ITEM1", result["data"]["items"][0]["item_cd"]
  end

  test "update rejects cancelled order" do
    order = OmInternalOrder.create!(
      ord_stat_cd: "CANCEL",
      wait_ord_internal_yn: "N",
      cancel_yn: "Y"
    )

    patch om_internal_order_url(order), params: {
      order: { remk: "변경 시도" }
    }, as: :json

    assert_response :unprocessable_entity
  end

  test "cancel sets cancel_yn to Y" do
    order = OmInternalOrder.create!(
      ord_stat_cd: "WAIT",
      wait_ord_internal_yn: "N",
      cancel_yn: "N"
    )

    post cancel_om_internal_order_url(order), as: :json
    assert_response :success

    result = JSON.parse(response.body)
    assert result["success"]
    assert_equal "Y", result["data"]["cancel_yn"]
    assert_equal "CANCEL", result["data"]["ord_stat_cd"]
  end

  test "cancel rejects already cancelled order" do
    order = OmInternalOrder.create!(
      ord_stat_cd: "CANCEL",
      wait_ord_internal_yn: "N",
      cancel_yn: "Y"
    )

    post cancel_om_internal_order_url(order), as: :json
    assert_response :unprocessable_entity
  end
end
