require "test_helper"

class Om::PreOrderReceptionErrorsControllerTest < ActionDispatch::IntegrationTest
  setup do
    post session_path, params: { email_address: "admin@example.com", password: "password" }
  end

  test "index responds to html and json" do
    OmPreOrderReception.create!(
      bef_ord_no: "BERR1001",
      cust_cd: "C000100",
      cust_nm: "고객100",
      cust_ord_no: "CUST-ORD-100",
      item_cd: "ITEM-100",
      item_nm: "품목100",
      qty: 10,
      wgt: 3,
      vol: 2,
      status_cd: OmPreOrderReception::STATUS_RECEIVED,
      use_yn: "Y"
    )
    OmPreOrderError.create!(
      upload_batch_no: "BATCH1001",
      line_no: 1,
      cust_ord_no: "CUST-ORD-100",
      item_cd: "ITEM-100",
      err_type_cd: "E100",
      err_msg: "필수값 누락",
      resolved_yn: "N",
      use_yn: "Y"
    )

    get om_pre_order_reception_errors_url
    assert_response :success

    get om_pre_order_reception_errors_url(format: :json)
    assert_response :success
    rows = JSON.parse(response.body)
    assert rows.any? { |row| row["cust_ord_no"] == "CUST-ORD-100" && row["item_cd"] == "ITEM-100" }
  end

  test "items returns detail rows for selected error" do
    OmPreOrderReception.create!(
      bef_ord_no: "BERR2001",
      cust_cd: "C000200",
      cust_nm: "고객200",
      cust_ord_no: "CUST-ORD-200",
      item_cd: "ITEM-200",
      item_nm: "품목200",
      qty: 5,
      wgt: 2,
      vol: 1,
      status_cd: OmPreOrderReception::STATUS_RECEIVED,
      use_yn: "Y"
    )
    first_error = OmPreOrderError.create!(
      upload_batch_no: "BATCH2001",
      line_no: 1,
      cust_ord_no: "CUST-ORD-200",
      item_cd: "ITEM-200",
      err_type_cd: "E201",
      err_msg: "주소 오류",
      resolved_yn: "N",
      use_yn: "Y"
    )
    OmPreOrderError.create!(
      upload_batch_no: "BATCH2001",
      line_no: 2,
      cust_ord_no: "CUST-ORD-200",
      item_cd: "ITEM-200",
      err_type_cd: "E202",
      err_msg: "수량 오류",
      resolved_yn: "N",
      use_yn: "Y"
    )

    get items_om_pre_order_reception_errors_url(format: :json), params: { error_id: first_error.id }
    assert_response :success

    rows = JSON.parse(response.body)
    assert_equal 2, rows.size
    assert_equal "주소 오류", rows.first["msg"]
    assert_equal 5.0, rows.first["qty"].to_f
  end

  test "reprocess creates order and resolves selected errors" do
    reception = OmPreOrderReception.create!(
      bef_ord_no: "BERR3001",
      cust_cd: "C000300",
      cust_nm: "고객300",
      cust_ord_no: "CUST-ORD-300",
      item_cd: "ITEM-300",
      item_nm: "품목300",
      qty: 7,
      wgt: 3,
      vol: 2,
      status_cd: OmPreOrderReception::STATUS_RECEIVED,
      use_yn: "Y"
    )
    error = OmPreOrderError.create!(
      upload_batch_no: "BATCH3001",
      line_no: 1,
      cust_ord_no: "CUST-ORD-300",
      item_cd: "ITEM-300",
      err_type_cd: "E301",
      err_msg: "검증 실패",
      resolved_yn: "N",
      use_yn: "Y"
    )

    post reprocess_om_pre_order_reception_errors_url, params: { error_ids: [ error.id ] }, as: :json
    assert_response :success

    created_order = OmOrder.find_by(cust_ord_no: "CUST-ORD-300")
    assert_not_nil created_order
    assert_equal "PRE_ORDER", created_order.ord_type_cd

    reception.reload
    assert_equal OmPreOrderReception::STATUS_ORDER_CREATED, reception.status_cd

    error.reload
    assert_equal "Y", error.resolved_yn
    assert_equal "N", error.use_yn
  end

  test "non-admin requires menu permission" do
    delete session_path
    user = User.find_by!(email_address: "user@example.com")
    AdmUserMenuPermission.where(user_id: user.id, menu_cd: "OM_PRE_ORD_ERR").delete_all
    post session_path, params: { email_address: "user@example.com", password: "password" }

    get om_pre_order_reception_errors_url(format: :json)
    assert_response :forbidden

    AdmUserMenuPermission.create!(user: user, menu_cd: "OM_PRE_ORD_ERR", use_yn: "Y")
    get om_pre_order_reception_errors_url(format: :json)
    assert_response :success
  end
end
