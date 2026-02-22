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
      rowsToDelete: ["BZ000011"]
    }, as: :json

    assert_response :success
    assert_equal "After", StdBusinessCertificate.find_by!(bzac_cd: "BZ000010").bzac_nm
    assert_equal "N", StdBusinessCertificate.find_by!(bzac_cd: "BZ000011").use_yn_cd
    assert StdBusinessCertificate.exists?(bzac_cd: "BZ000012")
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
