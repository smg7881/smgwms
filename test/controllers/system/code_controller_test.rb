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
          use_yn: "Y"
        }
      }, as: :json
    end

    assert_response :success
  end

  test "batch_save inserts updates and deletes" do
    AdmCodeHeader.create!(code: "EXIST01", code_name: "Before", use_yn: "Y")
    AdmCodeHeader.create!(code: "DEL01", code_name: "Delete Me", use_yn: "Y")

    post batch_save_system_code_index_url, params: {
      rowsToInsert: [ { code: "INS01", code_name: "Inserted", use_yn: "Y" } ],
      rowsToUpdate: [ { code: "EXIST01", code_name: "After", use_yn: "N" } ],
      rowsToDelete: [ "DEL01" ]
    }, as: :json

    assert_response :success
    assert_equal "Inserted", AdmCodeHeader.find_by!(code: "INS01").code_name
    assert_equal "After", AdmCodeHeader.find_by!(code: "EXIST01").code_name
    assert_not AdmCodeHeader.exists?(code: "DEL01")
  end

  test "non-admin cannot access code endpoints" do
    delete session_path
    post session_path, params: { email_address: "user@example.com", password: "password" }

    get system_code_index_url(format: :json)
    assert_response :forbidden
  end
end
