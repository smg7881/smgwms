require "test_helper"

class Om::CustomerOrderOfficersControllerTest < ActionDispatch::IntegrationTest
  setup do
    post session_path, params: { email_address: "admin@example.com", password: "password" }
  end

  test "index responds to html and json" do
    OmCustomerOrderOfficer.create!(
      ord_chrg_dept_cd: "D100",
      ord_chrg_dept_nm: "영업1팀",
      cust_cd: "C000100",
      cust_nm: "고객100",
      exp_imp_dom_sctn_cd: "DOMESTIC",
      cust_ofcr_nm: "담당자A",
      cust_ofcr_tel_no: "02-1111-2222",
      use_yn: "Y"
    )

    get om_customer_order_officers_url
    assert_response :success

    get om_customer_order_officers_url(format: :json)
    assert_response :success
    rows = JSON.parse(response.body)
    assert rows.any? { |row| row["ord_chrg_dept_cd"] == "D100" && row["cust_ofcr_nm"] == "담당자A" }
  end

  test "batch_save inserts updates and soft deletes rows" do
    row_to_update = OmCustomerOrderOfficer.create!(
      ord_chrg_dept_cd: "D101",
      ord_chrg_dept_nm: "영업2팀",
      cust_cd: "C000101",
      cust_nm: "고객101",
      exp_imp_dom_sctn_cd: "EXPORT",
      cust_ofcr_nm: "담당자B",
      cust_ofcr_tel_no: "02-3333-4444",
      use_yn: "Y"
    )

    row_to_delete = OmCustomerOrderOfficer.create!(
      ord_chrg_dept_cd: "D102",
      ord_chrg_dept_nm: "영업3팀",
      cust_cd: "C000102",
      cust_nm: "고객102",
      exp_imp_dom_sctn_cd: "IMPORT",
      cust_ofcr_nm: "담당자C",
      cust_ofcr_tel_no: "02-5555-6666",
      use_yn: "Y"
    )

    post batch_save_om_customer_order_officers_url, params: {
      rowsToInsert: [
        {
          ord_chrg_dept_cd: "D103",
          ord_chrg_dept_nm: "영업4팀",
          cust_cd: "C000103",
          cust_nm: "고객103",
          exp_imp_dom_sctn_cd: "DOMESTIC",
          cust_ofcr_nm: "담당자D",
          cust_ofcr_tel_no: "02-7777-8888",
          use_yn: "Y"
        }
      ],
      rowsToUpdate: [
        {
          id: row_to_update.id,
          ord_chrg_dept_cd: "D101",
          ord_chrg_dept_nm: "영업2팀",
          cust_cd: "C000101",
          cust_nm: "고객101",
          exp_imp_dom_sctn_cd: "EXPORT",
          cust_ofcr_nm: "담당자B",
          cust_ofcr_tel_no: "02-9999-0000",
          use_yn: "Y"
        }
      ],
      rowsToDelete: [row_to_delete.id]
    }, as: :json

    assert_response :success
    row_to_update.reload
    row_to_delete.reload

    assert_equal "02-9999-0000", row_to_update.cust_ofcr_tel_no
    assert_equal "N", row_to_delete.use_yn
    assert OmCustomerOrderOfficer.exists?(ord_chrg_dept_cd: "D103", cust_cd: "C000103", cust_ofcr_nm: "담당자D")
  end

  test "non-admin requires menu permission" do
    delete session_path
    user = User.find_by!(email_address: "user@example.com")
    AdmUserMenuPermission.where(user_id: user.id, menu_cd: "OM_CUST_ORD_OFCR").delete_all
    post session_path, params: { email_address: "user@example.com", password: "password" }

    get om_customer_order_officers_url(format: :json)
    assert_response :forbidden

    AdmUserMenuPermission.create!(user: user, menu_cd: "OM_CUST_ORD_OFCR", use_yn: "Y")
    get om_customer_order_officers_url(format: :json)
    assert_response :success
  end
end
