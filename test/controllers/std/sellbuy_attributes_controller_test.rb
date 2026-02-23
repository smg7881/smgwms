require "test_helper"

class Std::SellbuyAttributesControllerTest < ActionDispatch::IntegrationTest
  setup do
    post session_path, params: { email_address: "admin@example.com", password: "password" }
  end

  test "index responds to html and json" do
    StdSellbuyAttribute.create!(
      corp_cd: "C001",
      sellbuy_sctn_cd: "SELL",
      sellbuy_attr_cd: "00000001",
      sellbuy_attr_nm: "운송료",
      rdtn_nm: "운송",
      sellbuy_attr_eng_nm: "FREIGHT",
      use_yn_cd: "Y"
    )

    get std_sellbuy_attributes_url
    assert_response :success

    get std_sellbuy_attributes_url(format: :json)
    assert_response :success
    rows = JSON.parse(response.body)
    assert rows.any? { |row| row["sellbuy_attr_cd"] == "00000001" }
  end

  test "create update and destroy work with modal endpoints" do
    post std_sellbuy_attributes_url, params: {
      sellbuy_attribute: {
        corp_cd: "C001",
        sellbuy_sctn_cd: "SELL",
        sellbuy_attr_cd: "00000100",
        sellbuy_attr_nm: "초기항목",
        rdtn_nm: "초기",
        sellbuy_attr_eng_nm: "INITIAL",
        tran_yn_cd: "Y",
        use_yn_cd: "Y"
      }
    }, as: :json

    assert_response :success
    assert_equal "초기항목", StdSellbuyAttribute.find_by!(sellbuy_attr_cd: "00000100").sellbuy_attr_nm

    patch std_sellbuy_attribute_url("00000100"), params: {
      sellbuy_attribute: {
        sellbuy_attr_cd: "99999999",
        corp_cd: "C001",
        sellbuy_sctn_cd: "BOTH",
        sellbuy_attr_nm: "수정항목",
        rdtn_nm: "수정",
        sellbuy_attr_eng_nm: "UPDATED",
        strg_yn_cd: "Y",
        use_yn_cd: "Y"
      }
    }, as: :json

    assert_response :success
    row = StdSellbuyAttribute.find_by!(sellbuy_attr_cd: "00000100")
    assert_equal "수정항목", row.sellbuy_attr_nm
    assert_equal "BOTH", row.sellbuy_sctn_cd
    assert_equal "Y", row.strg_yn_cd

    delete std_sellbuy_attribute_url("00000100"), as: :json
    assert_response :success
    assert_equal "N", row.reload.use_yn_cd
  end

  test "non-admin requires menu permission" do
    delete session_path
    user = User.find_by!(email_address: "user@example.com")
    AdmUserMenuPermission.where(user_id: user.id, menu_cd: "STD_SELLBUY_ATTR").delete_all
    post session_path, params: { email_address: "user@example.com", password: "password" }

    get std_sellbuy_attributes_url(format: :json)
    assert_response :forbidden

    AdmUserMenuPermission.create!(user: user, menu_cd: "STD_SELLBUY_ATTR", use_yn: "Y")
    get std_sellbuy_attributes_url(format: :json)
    assert_response :success
  end
end
