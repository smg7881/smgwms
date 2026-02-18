require "test_helper"

class System::CodeDetailsControllerTest < ActionDispatch::IntegrationTest
  setup do
    post session_path, params: { email_address: "admin@example.com", password: "password" }
    @header = AdmCodeHeader.create!(code: "HDR01", code_name: "Header", use_yn: "Y")
  end

  test "index responds to json" do
    get system_code_details_url(@header.code, format: :json)
    assert_response :success
  end

  test "creates code detail" do
    assert_difference("AdmCodeDetail.count", 1) do
      post system_code_details_url(@header.code), params: {
        code_detail: {
          code: @header.code,
          detail_code: "D001",
          detail_code_name: "Detail Name",
          short_name: "D",
          ref_code: "",
          sort_order: 1,
          use_yn: "Y"
        }
      }, as: :json
    end

    assert_response :success
  end

  test "batch_save inserts updates and deletes details" do
    AdmCodeDetail.create!(code: @header.code, detail_code: "EX1", detail_code_name: "Before", sort_order: 1, use_yn: "Y")
    AdmCodeDetail.create!(code: @header.code, detail_code: "DEL1", detail_code_name: "Delete", sort_order: 2, use_yn: "Y")

    post batch_save_system_code_details_url(@header.code), params: {
      rowsToInsert: [ { detail_code: "INS1", detail_code_name: "Inserted", short_name: "", ref_code: "", sort_order: 3, use_yn: "Y" } ],
      rowsToUpdate: [ { detail_code: "EX1", detail_code_name: "After", short_name: "A", ref_code: "", sort_order: 1, use_yn: "N" } ],
      rowsToDelete: [ "DEL1" ]
    }, as: :json

    assert_response :success
    assert_equal "Inserted", AdmCodeDetail.find_by!(code: @header.code, detail_code: "INS1").detail_code_name
    assert_equal "After", AdmCodeDetail.find_by!(code: @header.code, detail_code: "EX1").detail_code_name
    assert_not AdmCodeDetail.exists?(code: @header.code, detail_code: "DEL1")
  end

  test "non-admin cannot access code detail endpoints" do
    delete session_path
    post session_path, params: { email_address: "user@example.com", password: "password" }

    get system_code_details_url(@header.code, format: :json)
    assert_response :forbidden
  end
end
