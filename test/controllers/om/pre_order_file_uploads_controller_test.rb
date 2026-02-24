require "csv"
require "tempfile"
require "test_helper"

class Om::PreOrderFileUploadsControllerTest < ActionDispatch::IntegrationTest
  setup do
    post session_path, params: { email_address: "admin@example.com", password: "password" }
  end

  test "index responds successfully" do
    get om_pre_order_file_uploads_url
    assert_response :success
  end

  test "preview returns validation summary" do
    with_upload_file([
      { bef_ord_no: "BEF001", cust_cd: "C000001", cust_ord_no: "CO0001", item_cd: "ITEM001", qty: 10, strt_req_ymd: "2026-02-24", aptd_req_ymd: "2026-02-25", dpt_ar_cd: "DPT001", arv_ar_cd: "ARV001" },
      { bef_ord_no: "BEF002", cust_cd: "C000001", cust_ord_no: "CO0002", item_cd: "", qty: 20, strt_req_ymd: "2026-02-24", aptd_req_ymd: "2026-02-23", dpt_ar_cd: "DPT001", arv_ar_cd: "ARV001" }
    ]) do |file|
      post preview_om_pre_order_file_uploads_url, params: { q: { upload_file: file } }
    end

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 2, body.dig("summary", "total_count")
    assert_equal 1, body.dig("summary", "error_count")
    assert_equal false, body["can_save"]
  end

  test "save persists batch reception and order for valid file" do
    assert_difference("OmPreOrderUploadBatch.count", +1) do
      assert_difference("OmPreOrderReception.count", +1) do
        assert_difference("OmOrder.count", +1) do
          with_upload_file([
            { bef_ord_no: "BEF003", cust_cd: "C000001", cust_ord_no: "CO0003", item_cd: "ITEM003", qty: 33, strt_req_ymd: "2026-02-24", aptd_req_ymd: "2026-02-26", dpt_ar_cd: "DPT003", arv_ar_cd: "ARV003" }
          ]) do |file|
            post save_om_pre_order_file_uploads_url, params: { q: { upload_file: file } }
          end
        end
      end
    end

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal true, body["success"]

    reception = OmPreOrderReception.find_by!(bef_ord_no: "BEF003")
    assert_equal OmPreOrderReception::STATUS_ORDER_CREATED, reception.status_cd

    order = OmOrder.find_by!(cust_ord_no: "CO0003", item_cd: "ITEM003")
    assert_equal "C000001", order.cust_cd
  end

  test "non-admin requires menu permission" do
    delete session_path
    user = User.find_by!(email_address: "user@example.com")
    AdmUserMenuPermission.where(user_id: user.id, menu_cd: "OM_PRE_ORD_FILE_UL").delete_all
    post session_path, params: { email_address: "user@example.com", password: "password" }

    with_upload_file([
      { bef_ord_no: "BEF004", cust_cd: "C000001", cust_ord_no: "CO0004", item_cd: "ITEM004", qty: 5, strt_req_ymd: "2026-02-24", aptd_req_ymd: "2026-02-25", dpt_ar_cd: "DPT004", arv_ar_cd: "ARV004" }
    ]) do |file|
      post preview_om_pre_order_file_uploads_url(format: :json), params: { q: { upload_file: file } }
    end
    assert_response :forbidden

    AdmUserMenuPermission.create!(user: user, menu_cd: "OM_PRE_ORD_FILE_UL", use_yn: "Y")

    with_upload_file([
      { bef_ord_no: "BEF005", cust_cd: "C000001", cust_ord_no: "CO0005", item_cd: "ITEM005", qty: 5, strt_req_ymd: "2026-02-24", aptd_req_ymd: "2026-02-25", dpt_ar_cd: "DPT005", arv_ar_cd: "ARV005" }
    ]) do |file|
      post preview_om_pre_order_file_uploads_url(format: :json), params: { q: { upload_file: file } }
    end
    assert_response :success
  end

  private
    def with_upload_file(rows)
      headers = %w[
        bef_ord_no ord_no cust_cd cust_ord_no ord_req_cust_cd bilg_cust_cd cust_ofcr_nm cust_ofcr_tel_no
        ord_type_cd cust_expr_yn retrngd_yn cargo_form_cd cust_bzac_cd dpt_ar_cd dpt_ar_type_cd dpt_ar_zip_cd
        strt_req_ymd aptd_req_ymd arv_ar_cd arv_ar_type_cd arv_ar_zip_cd line_no item_cd item_nm qty qty_unit_cd
        wgt wgt_unit_cd vol vol_unit_cd
      ]

      csv_body = CSV.generate do |csv|
        csv << headers
        rows.each do |row|
          csv << headers.map { |header| row[header.to_sym] || row[header] }
        end
      end

      Tempfile.create([ "pre_order_upload", ".csv" ]) do |tempfile|
        tempfile.write(csv_body)
        tempfile.rewind
        uploaded_file = Rack::Test::UploadedFile.new(tempfile.path, "text/csv", true, original_filename: "pre_order_upload.csv")
        yield uploaded_file
      end
    end
end
