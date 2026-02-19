require "test_helper"

class System::RolesControllerTest < ActionDispatch::IntegrationTest
  setup do
    post session_path, params: { email_address: "admin@example.com", password: "password" }
  end

  test "index responds to json" do
    get system_roles_url(format: :json)
    assert_response :success
  end

  test "batch_save inserts updates and deletes" do
    AdmRole.create!(role_cd: "EXIST_ROLE", role_nm: "기존역할", use_yn: "Y")
    AdmRole.create!(role_cd: "DEL_ROLE", role_nm: "삭제역할", use_yn: "Y")

    post batch_save_system_roles_url, params: {
      rowsToInsert: [ { role_cd: "NEW_ROLE", role_nm: "신규역할", description: "신규", use_yn: "Y" } ],
      rowsToUpdate: [ { role_cd: "EXIST_ROLE", role_nm: "수정역할", description: "수정", use_yn: "N" } ],
      rowsToDelete: [ "DEL_ROLE" ]
    }, as: :json

    assert_response :success
    assert_equal "신규역할", AdmRole.find_by!(role_cd: "NEW_ROLE").role_nm
    assert_equal "수정역할", AdmRole.find_by!(role_cd: "EXIST_ROLE").role_nm
    assert_equal "N", AdmRole.find_by!(role_cd: "EXIST_ROLE").use_yn
    assert_not AdmRole.exists?(role_cd: "DEL_ROLE")
  end

  test "non-admin cannot access roles endpoints" do
    delete session_path
    post session_path, params: { email_address: "user@example.com", password: "password" }

    get system_roles_url(format: :json)
    assert_response :forbidden
  end
end
