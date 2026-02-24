require "test_helper"

class System::CodeControllerTest < ActionDispatch::IntegrationTest
  setup do
    post session_path, params: { email_address: "admin@example.com", password: "password" }
  end

  test "index responds to json" do
    get system_code_index_url(format: :json)
    assert_response :success
  end

  test "creates code header" do
    assert_difference("AdmCodeHeader.count", 1) do
      post system_code_index_url, params: {
        code_header: {
          code: "TEST01",
          code_name: "Test Header",
          sys_sctn_cd: "WMS",
          rmk: "Create remark",
          use_yn: "Y"
        }
      }, as: :json
    end

    assert_response :success
    header = AdmCodeHeader.find_by!(code: "TEST01")
    assert_equal "WMS", header.sys_sctn_cd
    assert_equal "Create remark", header.rmk
  end

  test "batch_save inserts updates and deletes" do
    AdmCodeHeader.create!(code: "EXIST01", code_name: "Before", use_yn: "Y")
    AdmCodeHeader.create!(code: "DEL01", code_name: "Delete Me", use_yn: "Y")

    post batch_save_system_code_index_url, params: {
      rowsToInsert: [ { code: "INS01", code_name: "Inserted", sys_sctn_cd: "WMS", rmk: "Inserted remark", use_yn: "Y" } ],
      rowsToUpdate: [ { code: "EXIST01", code_name: "After", sys_sctn_cd: "ERP", rmk: "Updated remark", use_yn: "N" } ],
      rowsToDelete: [ "DEL01" ]
    }, as: :json

    assert_response :success
    inserted = AdmCodeHeader.find_by!(code: "INS01")
    updated = AdmCodeHeader.find_by!(code: "EXIST01")
    assert_equal "Inserted", inserted.code_name
    assert_equal "WMS", inserted.sys_sctn_cd
    assert_equal "Inserted remark", inserted.rmk
    assert_equal "After", updated.code_name
    assert_equal "ERP", updated.sys_sctn_cd
    assert_equal "Updated remark", updated.rmk
    assert_not AdmCodeHeader.exists?(code: "DEL01")
  end

  test "batch_save deletes header with details" do
    header = AdmCodeHeader.create!(code: "DEL02", code_name: "Delete With Details", use_yn: "Y")
    AdmCodeDetail.create!(code: header.code, detail_code: "D001", detail_code_name: "Detail", sort_order: 1, use_yn: "Y")

    post batch_save_system_code_index_url, params: {
      rowsToInsert: [],
      rowsToUpdate: [],
      rowsToDelete: [ header.code ]
    }, as: :json

    assert_response :success
    assert_not AdmCodeHeader.exists?(code: header.code)
    assert_not AdmCodeDetail.exists?(code: header.code, detail_code: "D001")
  end

  test "non-admin cannot access code endpoints" do
    delete session_path
    post session_path, params: { email_address: "user@example.com", password: "password" }

    get system_code_index_url(format: :json)
    assert_response :forbidden
  end
end
