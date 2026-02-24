require "test_helper"

class Om::CustomerSystemConfigsControllerTest < ActionDispatch::IntegrationTest
  setup do
    post session_path, params: { email_address: "admin@example.com", password: "password" }
  end

  test "index responds to html and json" do
    OmCustomerSystemConfig.create!(
      setup_unit_cd: "SYSTEM",
      cust_cd: "",
      lclas_cd: "TEST_LCLAS_A",
      mclas_cd: "TEST_MCLAS_A",
      sclas_cd: "TEST_SCLAS_A",
      setup_sctn_cd: "VALIDATE",
      module_nm: "품명",
      setup_value: "Y",
      use_yn: "Y"
    )

    get om_customer_system_configs_url
    assert_response :success

    get om_customer_system_configs_url(format: :json)
    assert_response :success
    rows = JSON.parse(response.body)
    assert rows.any? { |row| row["lclas_cd"] == "TEST_LCLAS_A" }
  end

  test "batch_save inserts updates and soft deletes rows" do
    existing = OmCustomerSystemConfig.create!(
      setup_unit_cd: "SYSTEM",
      cust_cd: "",
      lclas_cd: "TEST_LCLAS_B",
      mclas_cd: "TEST_MCLAS_B",
      sclas_cd: "TEST_SCLAS_B",
      setup_sctn_cd: "VALIDATE",
      module_nm: "오더생성",
      setup_value: "Y",
      use_yn: "Y"
    )

    post batch_save_om_customer_system_configs_url, params: {
      rowsToInsert: [
        {
          setup_unit_cd: "CUSTOMER",
          cust_cd: "C000001",
          lclas_cd: "TEST_LCLAS_C",
          mclas_cd: "TEST_MCLAS_C",
          sclas_cd: "TEST_SCLAS_C",
          setup_sctn_cd: "VALIDATE",
          module_nm: "오더전송",
          setup_value: "Y",
          use_yn: "Y"
        }
      ],
      rowsToUpdate: [
        {
          id: existing.id,
          setup_unit_cd: "SYSTEM",
          cust_cd: "",
          lclas_cd: "TEST_LCLAS_B",
          mclas_cd: "TEST_MCLAS_B",
          sclas_cd: "TEST_SCLAS_B",
          setup_sctn_cd: "VALIDATE",
          module_nm: "오더생성",
          setup_value: "N",
          use_yn: "Y"
        }
      ],
      rowsToDelete: [existing.id]
    }, as: :json

    assert_response :success
    existing.reload
    assert_equal "N", existing.use_yn
    assert OmCustomerSystemConfig.exists?(setup_unit_cd: "CUSTOMER", cust_cd: "C000001", lclas_cd: "TEST_LCLAS_C")
  end

  test "customer mode merges system defaults with customer overrides" do
    OmCustomerSystemConfig.create!(
      setup_unit_cd: "SYSTEM",
      cust_cd: "",
      lclas_cd: "MRG_LCLAS_A",
      mclas_cd: "MRG_MCLAS_A",
      sclas_cd: "MRG_SCLAS_A",
      setup_sctn_cd: "VALIDATE",
      module_nm: "기본값A",
      setup_value: "Y",
      use_yn: "Y"
    )

    OmCustomerSystemConfig.create!(
      setup_unit_cd: "CUSTOMER",
      cust_cd: "C000777",
      lclas_cd: "MRG_LCLAS_A",
      mclas_cd: "MRG_MCLAS_A",
      sclas_cd: "MRG_SCLAS_A",
      setup_sctn_cd: "VALIDATE",
      module_nm: "고객값A",
      setup_value: "N",
      use_yn: "Y"
    )

    OmCustomerSystemConfig.create!(
      setup_unit_cd: "SYSTEM",
      cust_cd: "",
      lclas_cd: "MRG_LCLAS_B",
      mclas_cd: "MRG_MCLAS_B",
      sclas_cd: "MRG_SCLAS_B",
      setup_sctn_cd: "VALIDATE",
      module_nm: "기본값B",
      setup_value: "Y",
      use_yn: "Y"
    )

    get om_customer_system_configs_url(format: :json), params: {
      q: {
        setup_unit_cd: "CUSTOMER",
        cust_cd: "C000777",
        use_yn: "Y"
      }
    }
    assert_response :success

    rows = JSON.parse(response.body)
    row_a = rows.find { |row| row["lclas_cd"] == "MRG_LCLAS_A" }
    row_b = rows.find { |row| row["lclas_cd"] == "MRG_LCLAS_B" }

    assert_equal "N", row_a["setup_value"]
    assert_equal false, row_a["from_system_default"]

    assert_equal "Y", row_b["setup_value"]
    assert_equal true, row_b["from_system_default"]
    assert_nil row_b["id"]
  end

  test "batch_save upserts from rowsToUpdate when key does not exist" do
    post batch_save_om_customer_system_configs_url, params: {
      rowsToInsert: [],
      rowsToUpdate: [
        {
          setup_unit_cd: "CUSTOMER",
          cust_cd: "C009999",
          lclas_cd: "UPS_LCLAS",
          mclas_cd: "UPS_MCLAS",
          sclas_cd: "UPS_SCLAS",
          setup_sctn_cd: "VALIDATE",
          module_nm: "upsert",
          setup_value: "Y",
          use_yn: "Y"
        }
      ],
      rowsToDelete: []
    }, as: :json

    assert_response :success
    assert OmCustomerSystemConfig.exists?(
      setup_unit_cd: "CUSTOMER",
      cust_cd: "C009999",
      lclas_cd: "UPS_LCLAS",
      mclas_cd: "UPS_MCLAS",
      sclas_cd: "UPS_SCLAS",
      setup_sctn_cd: "VALIDATE"
    )
  end

  test "non-admin requires menu permission" do
    delete session_path
    user = User.find_by!(email_address: "user@example.com")
    AdmUserMenuPermission.where(user_id: user.id, menu_cd: "OM_CUST_SYS_CONF").delete_all
    post session_path, params: { email_address: "user@example.com", password: "password" }

    get om_customer_system_configs_url(format: :json)
    assert_response :forbidden

    AdmUserMenuPermission.create!(user: user, menu_cd: "OM_CUST_SYS_CONF", use_yn: "Y")
    get om_customer_system_configs_url(format: :json)
    assert_response :success
  end
end
