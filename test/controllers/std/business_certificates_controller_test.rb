require "test_helper"

class Std::BusinessCertificatesControllerTest < ActionDispatch::IntegrationTest
  setup do
    post session_path, params: { email_address: "admin@example.com", password: "password" }
  end

  test "index responds to html and json" do
    StdBusinessCertificate.create!(
      bzac_cd: "BZ000001",
      bzac_nm: "Client A",
      compreg_slip: "1234567890",
      bizman_yn_cd: "BUSINESS",
      store_nm_cd: "Store",
      rptr_nm_cd: "Rep",
      dup_bzac_yn_cd: "N",
      use_yn_cd: "Y"
    )

    get std_business_certificates_url
    assert_response :success

    get std_business_certificates_url(format: :json)
    assert_response :success
    rows = JSON.parse(response.body)
    assert rows.any? { |row| row["bzac_cd"] == "BZ000001" }
  end

  test "batch_save inserts updates and soft deletes" do
    StdBusinessCertificate.create!(
      bzac_cd: "BZ000010",
      bzac_nm: "Before",
      compreg_slip: "1111111111",
      bizman_yn_cd: "BUSINESS",
      store_nm_cd: "Store",
      rptr_nm_cd: "Rep",
      dup_bzac_yn_cd: "N",
      use_yn_cd: "Y"
    )
    StdBusinessCertificate.create!(
      bzac_cd: "BZ000011",
      bzac_nm: "Delete",
      compreg_slip: "2222222222",
      bizman_yn_cd: "BUSINESS",
      store_nm_cd: "Store",
      rptr_nm_cd: "Rep",
      dup_bzac_yn_cd: "N",
      use_yn_cd: "Y"
    )

    post batch_save_std_business_certificates_url, params: {
      rowsToInsert: [
        {
          bzac_cd: "BZ000012",
          bzac_nm: "New",
          compreg_slip: "333-33-33333",
          bizman_yn_cd: "BUSINESS",
          store_nm_cd: "Store",
          rptr_nm_cd: "Rep",
          dup_bzac_yn_cd: "N",
          use_yn_cd: "Y"
        }
      ],
      rowsToUpdate: [
        {
          bzac_cd: "BZ000010",
          bzac_nm: "After",
          compreg_slip: "1111111111",
          bizman_yn_cd: "BUSINESS",
          store_nm_cd: "Store",
          rptr_nm_cd: "Rep",
          dup_bzac_yn_cd: "N",
          use_yn_cd: "Y"
        }
      ],
      rowsToDelete: [ "BZ000011" ]
    }, as: :json

    assert_response :success
    assert_equal "After", StdBusinessCertificate.find_by!(bzac_cd: "BZ000010").bzac_nm
    assert_equal "N", StdBusinessCertificate.find_by!(bzac_cd: "BZ000011").use_yn_cd
    assert StdBusinessCertificate.exists?(bzac_cd: "BZ000012")
  end

  test "create update and destroy work with modal endpoints" do
    post std_business_certificates_url, params: {
      std_business_certificate: {
        bzac_cd: "BZ001100",
        bzac_nm: "신규거래처",
        compreg_slip: "123-45-67890",
        bizman_yn_cd: "BUSINESS",
        store_nm_cd: "상호A",
        rptr_nm_cd: "대표A",
        dup_bzac_yn_cd: "N",
        use_yn_cd: "Y"
      }
    }, as: :json

    assert_response :success
    assert_equal "신규거래처", StdBusinessCertificate.find_by!(bzac_cd: "BZ001100").bzac_nm

    patch std_business_certificate_url("BZ001100"), params: {
      std_business_certificate: {
        bzac_cd: "BZ009999",
        bzac_nm: "수정거래처",
        compreg_slip: "9876543210",
        bizman_yn_cd: "BUSINESS",
        store_nm_cd: "상호B",
        rptr_nm_cd: "대표B",
        dup_bzac_yn_cd: "Y",
        use_yn_cd: "Y"
      }
    }, as: :json

    assert_response :success
    row = StdBusinessCertificate.find_by!(bzac_cd: "BZ001100")
    assert_equal "수정거래처", row.bzac_nm
    assert_equal "9876543210", row.compreg_slip
    assert_equal "Y", row.dup_bzac_yn_cd

    delete std_business_certificate_url("BZ001100"), as: :json
    assert_response :success
    assert_equal "N", row.reload.use_yn_cd
  end

  test "show includes attachment metadata" do
    row = StdBusinessCertificate.create!(
      bzac_cd: "BZ001200",
      bzac_nm: "Attach",
      compreg_slip: "1234567890",
      bizman_yn_cd: "BUSINESS",
      store_nm_cd: "Store",
      rptr_nm_cd: "Rep",
      dup_bzac_yn_cd: "N",
      use_yn_cd: "Y"
    )
    row.attachments.attach(
      io: StringIO.new("sample attachment"),
      filename: "biz-license.txt",
      content_type: "text/plain"
    )
    row.refresh_attached_file_name!(clear_if_empty: true)

    get std_business_certificate_url("BZ001200"), as: :json
    assert_response :success

    body = JSON.parse(response.body)
    assert_equal "BZ001200", body["bzac_cd"]
    assert_equal 1, body["attachments"].length
    assert_equal "biz-license.txt", body["attachments"][0]["filename"]
  end

  test "client_defaults returns mapped client basic data" do
    StdBzacMst.create!(
      bzac_cd: "BZC10001",
      bzac_nm: "테스트거래처",
      mngt_corp_cd: "C001",
      bizman_no: "1234567890",
      bzac_sctn_grp_cd: "CLIENT",
      bzac_sctn_cd: "GENERAL",
      bzac_kind_cd: "CORP",
      ctry_cd: "KR",
      rpt_sales_emp_cd: "EMP001",
      aply_strt_day_cd: Date.new(2026, 1, 1),
      use_yn_cd: "Y",
      tpl_logis_yn_cd: "N",
      if_yn_cd: "N",
      branch_yn_cd: "N",
      sell_bzac_yn_cd: "Y",
      pur_bzac_yn_cd: "Y",
      elec_taxbill_yn_cd: "N",
      zip_cd: "06236",
      addr_cd: "서울시 강남구",
      addr_dtl_cd: "테헤란로 1"
    )

    get client_defaults_std_business_certificates_url, params: { bzac_cd: "bzc10001" }, as: :json
    assert_response :success

    body = JSON.parse(response.body)
    assert_equal true, body["success"]
    assert_equal "BZC10001", body.dig("defaults", "bzac_cd")
    assert_equal "테스트거래처", body.dig("defaults", "bzac_nm")
    assert_equal "1234567890", body.dig("defaults", "compreg_slip")
    assert_equal "서울시 강남구", body.dig("defaults", "zipaddr_cd")
    assert_equal "테헤란로 1", body.dig("defaults", "dtl_addr_cd")
  end

  test "non-admin requires menu permission" do
    delete session_path
    user = User.find_by!(email_address: "user@example.com")
    AdmUserMenuPermission.where(user_id: user.id, menu_cd: "STD_BIZ_CERT").delete_all
    post session_path, params: { email_address: "user@example.com", password: "password" }

    get std_business_certificates_url(format: :json)
    assert_response :forbidden

    AdmUserMenuPermission.create!(user: user, menu_cd: "STD_BIZ_CERT", use_yn: "Y")
    get std_business_certificates_url(format: :json)
    assert_response :success
  end
end
