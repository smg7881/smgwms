require "test_helper"

class Std::ClientsControllerTest < ActionDispatch::IntegrationTest
  setup do
    post session_path, params: { email_address: "admin@example.com", password: "password" }
  end

  test "index responds to html and json" do
    StdBzacMst.create!(
      bzac_cd: "CL000001",
      bzac_nm: "Client A",
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

    get std_clients_url
    assert_response :success

    get std_clients_url(format: :json)
    assert_response :success

    rows = JSON.parse(response.body)
    assert rows.any? { |row| row["bzac_cd"] == "CL000001" }
  end

  test "batch_save inserts updates and soft deletes with history" do
    StdBzacMst.create!(
      bzac_cd: "CL000010",
      bzac_nm: "Before Update",
      mngt_corp_cd: "CORP01",
      bizman_no: "1111111111",
      bzac_sctn_grp_cd: "CUSTOMER",
      bzac_sctn_cd: "DOMESTIC",
      bzac_kind_cd: "CORP",
      ctry_cd: "KR",
      rpt_sales_emp_cd: "EMP01",
      aply_strt_day_cd: Date.current,
      use_yn_cd: "Y"
    )
    StdBzacMst.create!(
      bzac_cd: "CL000011",
      bzac_nm: "To Inactivate",
      mngt_corp_cd: "CORP01",
      bizman_no: "2222222222",
      bzac_sctn_grp_cd: "CUSTOMER",
      bzac_sctn_cd: "DOMESTIC",
      bzac_kind_cd: "CORP",
      ctry_cd: "KR",
      rpt_sales_emp_cd: "EMP01",
      aply_strt_day_cd: Date.current,
      use_yn_cd: "Y"
    )

    post batch_save_std_clients_url, params: {
      rowsToInsert: [
        {
          bzac_nm: "New Client",
          mngt_corp_cd: "CORP02",
          bizman_no: "333-33-33333",
          bzac_sctn_grp_cd: "CUSTOMER",
          bzac_sctn_cd: "DOMESTIC",
          bzac_kind_cd: "CORP",
          ctry_cd: "KR",
          rpt_sales_emp_cd: "EMP02",
          aply_strt_day_cd: Date.current,
          use_yn_cd: "Y"
        }
      ],
      rowsToUpdate: [
        {
          bzac_cd: "CL000010",
          bzac_nm: "After Update",
          mngt_corp_cd: "CORP01",
          bizman_no: "1111111111",
          bzac_sctn_grp_cd: "CUSTOMER",
          bzac_sctn_cd: "DOMESTIC",
          bzac_kind_cd: "CORP",
          ctry_cd: "KR",
          rpt_sales_emp_cd: "EMP01",
          aply_strt_day_cd: Date.current,
          use_yn_cd: "Y"
        }
      ],
      rowsToDelete: ["CL000011"]
    }, as: :json

    assert_response :success
    assert_equal "After Update", StdBzacMst.find_by!(bzac_cd: "CL000010").bzac_nm
    assert_equal "N", StdBzacMst.find_by!(bzac_cd: "CL000011").use_yn_cd
    assert StdBzacMst.exists?(bzac_nm: "New Client")
    assert StdCm04004.where(bzac_cd: "CL000010", changed_col_nm: "bzac_nm").exists?
  end

  test "contacts and workplaces batch save works for selected client" do
    client = StdBzacMst.create!(
      bzac_cd: "CL000020",
      bzac_nm: "Client B",
      mngt_corp_cd: "CORP01",
      bizman_no: "4444444444",
      bzac_sctn_grp_cd: "CUSTOMER",
      bzac_sctn_cd: "DOMESTIC",
      bzac_kind_cd: "CORP",
      ctry_cd: "KR",
      rpt_sales_emp_cd: "EMP01",
      aply_strt_day_cd: Date.current,
      use_yn_cd: "Y"
    )

    post batch_save_contacts_std_client_url(client.bzac_cd), params: {
      rowsToInsert: [{ nm_cd: "Manager One", email_cd: "manager@example.com", rpt_yn_cd: "Y", use_yn_cd: "Y" }],
      rowsToUpdate: [],
      rowsToDelete: []
    }, as: :json
    assert_response :success

    get contacts_std_client_url(client.bzac_cd, format: :json)
    assert_response :success
    contacts = JSON.parse(response.body)
    assert_equal "Manager One", contacts.first["nm_cd"]

    post batch_save_workplaces_std_client_url(client.bzac_cd), params: {
      rowsToInsert: [{ workpl_nm_cd: "Seoul WH", workpl_sctn_cd: "MAIN", use_yn_cd: "Y" }],
      rowsToUpdate: [],
      rowsToDelete: []
    }, as: :json
    assert_response :success

    get workplaces_std_client_url(client.bzac_cd, format: :json)
    assert_response :success
    workplaces = JSON.parse(response.body)
    assert_equal "Seoul WH", workplaces.first["workpl_nm_cd"]
  end

  test "non-admin without permission cannot access endpoints" do
    delete session_path
    user = User.find_by!(email_address: "user@example.com")
    AdmUserMenuPermission.where(user_id: user.id, menu_cd: "STD_CLIENT").delete_all
    post session_path, params: { email_address: "user@example.com", password: "password" }

    get std_clients_url(format: :json)
    assert_response :forbidden
  end

  test "non-admin with permission can access endpoints" do
    user = User.find_by!(email_address: "user@example.com")
    AdmUserMenuPermission.find_or_create_by!(user: user, menu_cd: "STD_CLIENT") do |permission|
      permission.use_yn = "Y"
    end

    delete session_path
    post session_path, params: { email_address: "user@example.com", password: "password" }

    get std_clients_url(format: :json)
    assert_response :success
  end
end
