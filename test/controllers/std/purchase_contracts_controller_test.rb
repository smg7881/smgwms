require "test_helper"

class Std::PurchaseContractsControllerTest < ActionDispatch::IntegrationTest
  setup do
    post session_path, params: { email_address: "admin@example.com", password: "password" }
  end

  test "index responds to html and json" do
    StdPurchaseContract.create!(
      corp_cd: "CORP01",
      bzac_cd: "BZAC01",
      pur_ctrt_no: "PC00001000",
      pur_ctrt_nm: "매입계약 A",
      bizman_no: "1234567890",
      ctrt_sctn_cd: "GENERAL",
      ctrt_kind_cd: "NORMAL",
      use_yn_cd: "Y"
    )

    get std_purchase_contracts_url
    assert_response :success

    get std_purchase_contracts_url(format: :json)
    assert_response :success
    rows = JSON.parse(response.body)
    assert rows.any? { |row| row["pur_ctrt_no"] == "PC00001000" }
  end

  test "batch_save inserts updates and soft deletes with history" do
    StdPurchaseContract.create!(
      corp_cd: "CORP01",
      bzac_cd: "BZAC01",
      pur_ctrt_no: "PC00002000",
      pur_ctrt_nm: "변경전 계약",
      bizman_no: "1111111111",
      ctrt_sctn_cd: "GENERAL",
      ctrt_kind_cd: "NORMAL",
      use_yn_cd: "Y"
    )
    StdPurchaseContract.create!(
      corp_cd: "CORP01",
      bzac_cd: "BZAC01",
      pur_ctrt_no: "PC00002001",
      pur_ctrt_nm: "삭제 대상 계약",
      bizman_no: "2222222222",
      ctrt_sctn_cd: "GENERAL",
      ctrt_kind_cd: "NORMAL",
      use_yn_cd: "Y"
    )

    post batch_save_std_purchase_contracts_url, params: {
      rowsToInsert: [
        {
          corp_cd: "CORP02",
          bzac_cd: "BZAC02",
          pur_ctrt_nm: "신규 계약",
          bizman_no: "3333333333",
          ctrt_sctn_cd: "SPECIAL",
          ctrt_kind_cd: "SPOT",
          use_yn_cd: "Y"
        }
      ],
      rowsToUpdate: [
        {
          pur_ctrt_no: "PC00002000",
          corp_cd: "CORP01",
          bzac_cd: "BZAC01",
          pur_ctrt_nm: "변경후 계약",
          bizman_no: "1111111111",
          ctrt_sctn_cd: "GENERAL",
          ctrt_kind_cd: "NORMAL",
          use_yn_cd: "Y"
        }
      ],
      rowsToDelete: [ "PC00002001" ]
    }, as: :json

    assert_response :success
    assert_equal "변경후 계약", StdPurchaseContract.find_by!(pur_ctrt_no: "PC00002000").pur_ctrt_nm
    assert_equal "N", StdPurchaseContract.find_by!(pur_ctrt_no: "PC00002001").use_yn_cd
    assert StdPurchaseContract.exists?(pur_ctrt_nm: "신규 계약")
    changed_contract = StdPurchaseContract.find_by!(pur_ctrt_no: "PC00002000")
    assert StdPurchaseContractChangeHistory.where(purchase_contract_id: changed_contract.id, chg_col_nm: "pur_ctrt_nm").exists?
  end

  test "settlements batch save and history endpoints work" do
    contract = StdPurchaseContract.create!(
      corp_cd: "CORP01",
      bzac_cd: "BZAC01",
      pur_ctrt_no: "PC00003000",
      pur_ctrt_nm: "정산 테스트 계약",
      bizman_no: "4444444444",
      ctrt_sctn_cd: "GENERAL",
      ctrt_kind_cd: "NORMAL",
      use_yn_cd: "Y"
    )

    post batch_save_settlements_std_purchase_contract_url(contract.pur_ctrt_no), params: {
      rowsToInsert: [
        {
          seq_no: 1,
          fnc_or_cd: "KDB",
          fnc_or_nm: "KDB",
          acnt_no_cd: "110-111-2222",
          mon_cd: "KRW",
          use_yn_cd: "Y"
        }
      ],
      rowsToUpdate: [],
      rowsToDelete: []
    }, as: :json
    assert_response :success

    get settlements_std_purchase_contract_url(contract.pur_ctrt_no, format: :json)
    assert_response :success
    settlements = JSON.parse(response.body)
    assert_equal "KDB", settlements.first["fnc_or_cd"]

    get change_histories_std_purchase_contract_url(contract.pur_ctrt_no, format: :json)
    assert_response :success
  end

  test "non-admin without permission cannot access" do
    delete session_path
    user = User.find_by!(email_address: "user@example.com")
    AdmUserMenuPermission.where(user_id: user.id, menu_cd: "STD_PUR_CONTRACT").delete_all
    post session_path, params: { email_address: "user@example.com", password: "password" }

    get std_purchase_contracts_url(format: :json)
    assert_response :forbidden
  end

  test "non-admin with permission can access" do
    user = User.find_by!(email_address: "user@example.com")
    AdmUserMenuPermission.find_or_create_by!(user: user, menu_cd: "STD_PUR_CONTRACT") do |permission|
      permission.use_yn = "Y"
    end

    delete session_path
    post session_path, params: { email_address: "user@example.com", password: "password" }

    get std_purchase_contracts_url(format: :json)
    assert_response :success
  end
end
