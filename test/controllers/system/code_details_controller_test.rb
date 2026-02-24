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
          upper_code: "PARENT",
          upper_detail_code: "P001",
          rmk: "Create remark",
          attr1: "A1",
          attr2: "A2",
          attr3: "A3",
          attr4: "A4",
          attr5: "A5",
          sort_order: 1,
          use_yn: "Y"
        }
      }, as: :json
    end

    assert_response :success
    detail = AdmCodeDetail.find_by!(code: @header.code, detail_code: "D001")
    assert_equal "PARENT", detail.upper_code
    assert_equal "P001", detail.upper_detail_code
    assert_equal "Create remark", detail.rmk
    assert_equal "A5", detail.attr5
  end

  test "batch_save inserts updates and deletes details" do
    AdmCodeDetail.create!(code: @header.code, detail_code: "EX1", detail_code_name: "Before", sort_order: 1, use_yn: "Y")
    AdmCodeDetail.create!(code: @header.code, detail_code: "DEL1", detail_code_name: "Delete", sort_order: 2, use_yn: "Y")

    post batch_save_system_code_details_url(@header.code), params: {
      rowsToInsert: [ { detail_code: "INS1", detail_code_name: "Inserted", short_name: "", upper_code: "UP01", upper_detail_code: "UPD01", rmk: "Insert remark", attr1: "I1", attr2: "", attr3: "", attr4: "", attr5: "", sort_order: 3, use_yn: "Y" } ],
      rowsToUpdate: [ { detail_code: "EX1", detail_code_name: "After", short_name: "A", upper_code: "UP02", upper_detail_code: "UPD02", rmk: "Update remark", attr1: "U1", attr2: "U2", attr3: "", attr4: "", attr5: "", sort_order: 1, use_yn: "N" } ],
      rowsToDelete: [ "DEL1" ]
    }, as: :json

    assert_response :success
    inserted = AdmCodeDetail.find_by!(code: @header.code, detail_code: "INS1")
    updated = AdmCodeDetail.find_by!(code: @header.code, detail_code: "EX1")
    assert_equal "Inserted", inserted.detail_code_name
    assert_equal "UP01", inserted.upper_code
    assert_equal "UPD01", inserted.upper_detail_code
    assert_equal "Insert remark", inserted.rmk
    assert_equal "After", updated.detail_code_name
    assert_equal "UP02", updated.upper_code
    assert_equal "UPD02", updated.upper_detail_code
    assert_equal "Update remark", updated.rmk
    assert_equal "U2", updated.attr2
    assert_not AdmCodeDetail.exists?(code: @header.code, detail_code: "DEL1")
  end

  test "non-admin cannot access code detail endpoints" do
    delete session_path
    post session_path, params: { email_address: "user@example.com", password: "password" }

    get system_code_details_url(@header.code, format: :json)
    assert_response :forbidden
  end
end
