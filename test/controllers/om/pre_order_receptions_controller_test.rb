require "test_helper"

class Om::PreOrderReceptionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    post session_path, params: { email_address: "admin@example.com", password: "password" }
  end

  test "index responds to html and json" do
    OmPreOrderReception.create!(
      bef_ord_no: "BEF0001",
      cust_cd: "C000100",
      cust_nm: "Customer A",
      cust_ord_no: "CO0001",
      item_cd: "ITEM01",
      item_nm: "Item 01",
      qty: 10,
      status_cd: OmPreOrderReception::STATUS_RECEIVED,
      use_yn: "Y"
    )

    get om_pre_order_receptions_url
    assert_response :success

    get om_pre_order_receptions_url(format: :json)
    assert_response :success
    rows = JSON.parse(response.body)
    assert rows.any? { |row| row["bef_ord_no"] == "BEF0001" && row["cust_cd"] == "C000100" }
  end

  test "items returns rows for selected customer order number" do
    OmPreOrderReception.create!(
      bef_ord_no: "BEF1001",
      cust_cd: "C000200",
      cust_nm: "Customer B",
      cust_ord_no: "CO1000",
      item_cd: "ITEM10",
      item_nm: "Item 10",
      qty: 5,
      status_cd: OmPreOrderReception::STATUS_RECEIVED,
      use_yn: "Y"
    )
    OmPreOrderReception.create!(
      bef_ord_no: "BEF1002",
      cust_cd: "C000200",
      cust_nm: "Customer B",
      cust_ord_no: "CO1000",
      item_cd: "ITEM11",
      item_nm: "Item 11",
      qty: 3,
      status_cd: OmPreOrderReception::STATUS_RECEIVED,
      use_yn: "Y"
    )

    get items_om_pre_order_receptions_url, params: { cust_ord_no: "CO1000" }, as: :json
    assert_response :success

    rows = JSON.parse(response.body)
    assert_equal 2, rows.size
    assert rows.any? { |row| row["item_cd"] == "ITEM10" }
    assert rows.any? { |row| row["item_cd"] == "ITEM11" }
  end

  test "create_orders creates orders and updates pre order status" do
    pre_order = OmPreOrderReception.create!(
      bef_ord_no: "BEF2001",
      cust_cd: "C000300",
      cust_nm: "Customer C",
      cust_ord_no: "CO2000",
      item_cd: "ITEM20",
      item_nm: "Item 20",
      qty: 12,
      wgt: 1.2,
      vol: 0.8,
      status_cd: OmPreOrderReception::STATUS_RECEIVED,
      use_yn: "Y"
    )

    post create_orders_om_pre_order_receptions_url, params: {
      bef_ord_nos: [ pre_order.bef_ord_no ]
    }, as: :json

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal true, body["success"]

    pre_order.reload
    assert_equal OmPreOrderReception::STATUS_ORDER_CREATED, pre_order.status_cd

    created_order = OmOrder.find_by(cust_ord_no: "CO2000", item_cd: "ITEM20")
    assert_not_nil created_order
    assert_equal "ORDER_CREATED", created_order.ord_stat_cd
    assert_equal "PRE_ORDER", created_order.ord_type_cd
  end

  test "non-admin requires menu permission" do
    delete session_path
    user = User.find_by!(email_address: "user@example.com")
    AdmUserMenuPermission.where(user_id: user.id, menu_cd: "OM_PRE_ORD_RECP").delete_all
    post session_path, params: { email_address: "user@example.com", password: "password" }

    get om_pre_order_receptions_url(format: :json)
    assert_response :forbidden

    AdmUserMenuPermission.create!(user: user, menu_cd: "OM_PRE_ORD_RECP", use_yn: "Y")
    get om_pre_order_receptions_url(format: :json)
    assert_response :success
  end
end
