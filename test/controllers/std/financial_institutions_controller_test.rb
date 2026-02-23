require "test_helper"

class Std::FinancialInstitutionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    post session_path, params: { email_address: "admin@example.com", password: "password" }
  end

  test "index responds to html and json" do
    StdFinancialInstitution.create!(
      fnc_or_cd: "KDB",
      fnc_or_nm: "산업은행",
      fnc_or_eng_nm: "KOREA DEVELOPMENT BANK",
      ctry_cd: "KR",
      ctry_nm: "대한민국",
      use_yn_cd: "Y"
    )

    get std_financial_institutions_url
    assert_response :success

    get std_financial_institutions_url(format: :json)
    assert_response :success
    rows = JSON.parse(response.body)
    assert rows.any? { |row| row["fnc_or_cd"] == "KDB" }
  end

  test "batch_save inserts updates and soft deletes" do
    StdFinancialInstitution.create!(fnc_or_cd: "KDB", fnc_or_nm: "산업은행", fnc_or_eng_nm: "KDB", ctry_cd: "KR", ctry_nm: "대한민국", use_yn_cd: "Y")
    StdFinancialInstitution.create!(fnc_or_cd: "HANA", fnc_or_nm: "하나은행", fnc_or_eng_nm: "HANA", ctry_cd: "KR", ctry_nm: "대한민국", use_yn_cd: "Y")

    post batch_save_std_financial_institutions_url, params: {
      rowsToInsert: [ { fnc_or_cd: "WOORI", fnc_or_nm: "우리은행", fnc_or_eng_nm: "WOORI", ctry_cd: "KR", ctry_nm: "대한민국", use_yn_cd: "Y" } ],
      rowsToUpdate: [ { fnc_or_cd: "KDB", fnc_or_nm: "산업은행수정", fnc_or_eng_nm: "KOREA DEVELOPMENT BANK", ctry_cd: "KR", ctry_nm: "대한민국", use_yn_cd: "Y" } ],
      rowsToDelete: [ "HANA" ]
    }, as: :json

    assert_response :success
    assert_equal "산업은행수정", StdFinancialInstitution.find_by!(fnc_or_cd: "KDB").fnc_or_nm
    assert_equal "N", StdFinancialInstitution.find_by!(fnc_or_cd: "HANA").use_yn_cd
    assert StdFinancialInstitution.exists?(fnc_or_cd: "WOORI")
  end

  test "non-admin requires menu permission" do
    delete session_path
    user = User.find_by!(email_address: "user@example.com")
    AdmUserMenuPermission.where(user_id: user.id, menu_cd: "STD_FIN_ORG").delete_all
    post session_path, params: { email_address: "user@example.com", password: "password" }

    get std_financial_institutions_url(format: :json)
    assert_response :forbidden

    AdmUserMenuPermission.create!(user: user, menu_cd: "STD_FIN_ORG", use_yn: "Y")
    get std_financial_institutions_url(format: :json)
    assert_response :success
  end
end
