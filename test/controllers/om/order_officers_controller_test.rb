require "test_helper"

class Om::OrderOfficersControllerTest < ActionDispatch::IntegrationTest
  setup do
    post session_path, params: { email_address: "admin@example.com", password: "password" }
  end

  test "index responds to html and json" do
    OmOrderOfficer.create!(
      ord_chrg_dept_cd: "D100",
      ord_chrg_dept_nm: "운영1팀",
      cust_cd: "C000100",
      cust_nm: "고객100",
      exp_imp_dom_sctn_cd: "DOMESTIC",
      ofcr_cd: "USER01",
      ofcr_nm: "담당자A",
      tel_no: "02-1111-2222",
      mbp_no: "010-1111-2222",
      use_yn: "Y"
    )

    get om_order_officers_url
    assert_response :success

    get om_order_officers_url(format: :json)
    assert_response :success
    rows = JSON.parse(response.body)
    assert rows.any? { |row| row["ord_chrg_dept_cd"] == "D100" && row["ofcr_cd"] == "USER01" }
  end

  test "batch_save inserts updates and soft deletes rows" do
    row_to_update = OmOrderOfficer.create!(
      ord_chrg_dept_cd: "D101",
      ord_chrg_dept_nm: "운영2팀",
      cust_cd: "C000101",
      cust_nm: "고객101",
      exp_imp_dom_sctn_cd: "EXPORT",
      ofcr_cd: "USER11",
      ofcr_nm: "담당자B",
      tel_no: "02-3333-4444",
      mbp_no: "010-3333-4444",
      use_yn: "Y"
    )

    row_to_delete = OmOrderOfficer.create!(
      ord_chrg_dept_cd: "D102",
      ord_chrg_dept_nm: "운영3팀",
      cust_cd: "C000102",
      cust_nm: "고객102",
      exp_imp_dom_sctn_cd: "IMPORT",
      ofcr_cd: "USER12",
      ofcr_nm: "담당자C",
      tel_no: "02-5555-6666",
      mbp_no: "010-5555-6666",
      use_yn: "Y"
    )

    post batch_save_om_order_officers_url, params: {
      rowsToInsert: [
        {
          ord_chrg_dept_cd: "D103",
          ord_chrg_dept_nm: "운영4팀",
          cust_cd: "C000103",
          cust_nm: "고객103",
          exp_imp_dom_sctn_cd: "DOMESTIC",
          ofcr_cd: "USER13",
          ofcr_nm: "담당자D",
          tel_no: "02-7777-8888",
          mbp_no: "010-7777-8888",
          use_yn: "Y"
        }
      ],
      rowsToUpdate: [
        {
          id: row_to_update.id,
          ord_chrg_dept_cd: "D101",
          ord_chrg_dept_nm: "운영2팀",
          cust_cd: "C000101",
          cust_nm: "고객101",
          exp_imp_dom_sctn_cd: "EXPORT",
          ofcr_cd: "USER11",
          ofcr_nm: "담당자B",
          tel_no: "02-9999-0000",
          mbp_no: "010-9999-0000",
          use_yn: "Y"
        }
      ],
      rowsToDelete: [ row_to_delete.id ]
    }, as: :json

    assert_response :success
    row_to_update.reload
    row_to_delete.reload

    assert_equal "02-9999-0000", row_to_update.tel_no
    assert_equal "N", row_to_delete.use_yn
    assert OmOrderOfficer.exists?(ord_chrg_dept_cd: "D103", cust_cd: "C000103", ofcr_cd: "USER13")
  end

  test "non-admin requires menu permission" do
    delete session_path
    user = User.find_by!(email_address: "user@example.com")
    AdmUserMenuPermission.where(user_id: user.id, menu_cd: "OM_ORD_OFCR").delete_all
    post session_path, params: { email_address: "user@example.com", password: "password" }

    get om_order_officers_url(format: :json)
    assert_response :forbidden

    AdmUserMenuPermission.create!(user: user, menu_cd: "OM_ORD_OFCR", use_yn: "Y")
    get om_order_officers_url(format: :json)
    assert_response :success
  end
end
