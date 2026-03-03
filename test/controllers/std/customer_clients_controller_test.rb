require "test_helper"

class Std::CustomerClientsControllerTest < ActionDispatch::IntegrationTest
  setup do
    post session_path, params: { email_address: "admin@example.com", password: "password" }
    StdCm04004.delete_all
    StdBzacOfcr.delete_all
    StdBzacWorkpl.delete_all
    StdBzacMst.delete_all
  end

  test "index shows only customer section group rows" do
    StdBzacMst.create!(
      bzac_cd: "CC000001",
      bzac_nm: "고객거래처 A",
      mngt_corp_cd: "CORP01",
      bizman_no: "1234567890",
      bzac_sctn_grp_cd: "CUSTOMER",
      bzac_sctn_cd: "DOMESTIC",
      bzac_kind_cd: "CORP",
      ctry_cd: "KR",
      rpt_sales_emp_cd: "EMP01",
      aply_strt_day_cd: Date.current,
      use_yn_cd: "Y"
    )
    StdBzacMst.create!(
      bzac_cd: "PC000001",
      bzac_nm: "협력거래처 A",
      mngt_corp_cd: "CORP01",
      bizman_no: "2234567890",
      bzac_sctn_grp_cd: "PARTNER",
      bzac_sctn_cd: "SUPPLIER",
      bzac_kind_cd: "CORP",
      ctry_cd: "KR",
      rpt_sales_emp_cd: "EMP02",
      aply_strt_day_cd: Date.current,
      use_yn_cd: "Y"
    )

    get std_customer_clients_url
    assert_response :success

    get std_customer_clients_url(format: :json)
    assert_response :success

    rows = JSON.parse(response.body)
    assert_equal [ "CC000001" ], rows.map { |row| row["bzac_cd"] }
  end

  test "batch_save insert forces customer section group and blocks non-customer updates" do
    partner = StdBzacMst.create!(
      bzac_cd: "PC000010",
      bzac_nm: "협력거래처 수정대상",
      mngt_corp_cd: "CORP01",
      bizman_no: "3234567890",
      bzac_sctn_grp_cd: "PARTNER",
      bzac_sctn_cd: "SUPPLIER",
      bzac_kind_cd: "CORP",
      ctry_cd: "KR",
      rpt_sales_emp_cd: "EMP01",
      aply_strt_day_cd: Date.current,
      use_yn_cd: "Y"
    )

    post batch_save_std_customer_clients_url, params: {
      rowsToInsert: [
        {
          bzac_nm: "신규 고객거래처",
          mngt_corp_cd: "CORP02",
          bizman_no: "111-22-33333",
          bzac_sctn_grp_cd: "PARTNER",
          bzac_sctn_cd: "DOMESTIC",
          bzac_kind_cd: "CORP",
          ctry_cd: "KR",
          rpt_sales_emp_cd: "EMP03",
          aply_strt_day_cd: Date.current,
          use_yn_cd: "Y"
        }
      ],
      rowsToUpdate: [
        {
          bzac_cd: partner.bzac_cd,
          bzac_nm: "허용되지 않는 수정"
        }
      ],
      rowsToDelete: []
    }, as: :json

    assert_response :unprocessable_entity
    partner.reload
    assert_equal "협력거래처 수정대상", partner.bzac_nm

    post batch_save_std_customer_clients_url, params: {
      rowsToInsert: [
        {
          bzac_nm: "신규 고객거래처",
          mngt_corp_cd: "CORP02",
          bizman_no: "111-22-33333",
          bzac_sctn_grp_cd: "PARTNER",
          bzac_sctn_cd: "DOMESTIC",
          bzac_kind_cd: "CORP",
          ctry_cd: "KR",
          rpt_sales_emp_cd: "EMP03",
          aply_strt_day_cd: Date.current,
          use_yn_cd: "Y"
        }
      ],
      rowsToUpdate: [],
      rowsToDelete: []
    }, as: :json

    assert_response :success
    created = StdBzacMst.find_by!(bzac_nm: "신규 고객거래처")
    assert_equal "CUSTOMER", created.bzac_sctn_grp_cd
  end

  test "contacts and workplaces endpoints work for customer client" do
    customer = StdBzacMst.create!(
      bzac_cd: "CC000020",
      bzac_nm: "고객거래처 B",
      mngt_corp_cd: "CORP01",
      bizman_no: "4234567890",
      bzac_sctn_grp_cd: "CUSTOMER",
      bzac_sctn_cd: "OVERSEAS",
      bzac_kind_cd: "CORP",
      ctry_cd: "US",
      rpt_sales_emp_cd: "EMP04",
      aply_strt_day_cd: Date.current,
      use_yn_cd: "Y"
    )

    post batch_save_contacts_std_customer_client_url(customer.bzac_cd), params: {
      rowsToInsert: [ { nm_cd: "담당자A", rpt_yn_cd: "Y", use_yn_cd: "Y" } ],
      rowsToUpdate: [],
      rowsToDelete: []
    }, as: :json
    assert_response :success

    get contacts_std_customer_client_url(customer.bzac_cd, format: :json)
    assert_response :success
    contacts = JSON.parse(response.body)
    assert_equal "담당자A", contacts.first["nm_cd"]

    post batch_save_workplaces_std_customer_client_url(customer.bzac_cd), params: {
      rowsToInsert: [ { workpl_nm_cd: "고객작업장A", workpl_sctn_cd: "MAIN", use_yn_cd: "Y" } ],
      rowsToUpdate: [],
      rowsToDelete: []
    }, as: :json
    assert_response :success

    get workplaces_std_customer_client_url(customer.bzac_cd, format: :json)
    assert_response :success
    workplaces = JSON.parse(response.body)
    assert_equal "고객작업장A", workplaces.first["workpl_nm_cd"]
  end

  test "non-admin permission is checked with SALES_CUST_CLIENT" do
    delete session_path
    user = User.find_by!(email_address: "user@example.com")
    AdmUserMenuPermission.where(user_id: user.id, menu_cd: "SALES_CUST_CLIENT").delete_all
    post session_path, params: { email_address: "user@example.com", password: "password" }

    get std_customer_clients_url(format: :json)
    assert_response :forbidden

    AdmUserMenuPermission.find_or_create_by!(user: user, menu_cd: "SALES_CUST_CLIENT") do |permission|
      permission.use_yn = "Y"
    end

    get std_customer_clients_url(format: :json)
    assert_response :success
  end
end
