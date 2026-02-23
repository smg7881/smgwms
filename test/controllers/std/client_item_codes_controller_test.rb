require "test_helper"

class Std::ClientItemCodesControllerTest < ActionDispatch::IntegrationTest
  setup do
    post session_path, params: { email_address: "admin@example.com", password: "password" }
  end

  test "index responds to html and json" do
    StdClientItemCode.create!(
      item_cd: "ITEM001",
      item_nm: "테스트아이템",
      bzac_cd: "C001",
      goodsnm_cd: "G001",
      danger_yn_cd: "N",
      png_yn_cd: "N",
      mstair_lading_yn_cd: "N",
      if_yn_cd: "N",
      use_yn_cd: "Y",
      prod_nm_cd: "제조사"
    )

    get std_client_item_codes_url
    assert_response :success

    get std_client_item_codes_url(format: :json)
    assert_response :success
    rows = JSON.parse(response.body)
    assert rows.any? { |row| row["item_cd"] == "ITEM001" }
  end

  test "create update and destroy work with modal endpoints" do
    post std_client_item_codes_url, params: {
      client_item_code: {
        item_cd: "ITEM100",
        item_nm: "신규아이템",
        bzac_cd: "C001",
        goodsnm_cd: "G001",
        danger_yn_cd: "Y",
        png_yn_cd: "N",
        mstair_lading_yn_cd: "N",
        if_yn_cd: "Y",
        wgt_unit_cd: "KG",
        qty_unit_cd: "EA",
        tmpt_unit_cd: "C",
        vol_unit_cd: "CBM",
        basis_unit_cd: "EA",
        len_unit_cd: "M",
        pckg_qty: 12,
        tot_wgt_kg: 50.5,
        net_wgt_kg: 48.0,
        use_yn_cd: "Y",
        prod_nm_cd: "제조사A"
      }
    }, as: :json

    assert_response :success
    row = StdClientItemCode.find_by!(item_cd: "ITEM100", bzac_cd: "C001")
    assert_equal "신규아이템", row.item_nm
    assert_equal "Y", row.if_yn_cd

    patch std_client_item_code_url(row.id), params: {
      client_item_code: {
        item_cd: "ITEM100",
        item_nm: "수정아이템",
        bzac_cd: "C001",
        goodsnm_cd: "G001",
        danger_yn_cd: "N",
        png_yn_cd: "Y",
        mstair_lading_yn_cd: "Y",
        if_yn_cd: "N",
        use_yn_cd: "Y",
        prod_nm_cd: "제조사B"
      }
    }, as: :json

    assert_response :success
    row.reload
    assert_equal "수정아이템", row.item_nm
    assert_equal "Y", row.png_yn_cd
    assert_equal "제조사B", row.prod_nm_cd

    delete std_client_item_code_url(row.id), as: :json
    assert_response :success
    assert_equal "N", row.reload.use_yn_cd
  end

  test "non-admin requires menu permission" do
    delete session_path
    user = User.find_by!(email_address: "user@example.com")
    AdmUserMenuPermission.where(user_id: user.id, menu_cd: "STD_CLIENT_ITEM").delete_all
    post session_path, params: { email_address: "user@example.com", password: "password" }

    get std_client_item_codes_url(format: :json)
    assert_response :forbidden

    AdmUserMenuPermission.create!(user: user, menu_cd: "STD_CLIENT_ITEM", use_yn: "Y")
    get std_client_item_codes_url(format: :json)
    assert_response :success
  end
end
