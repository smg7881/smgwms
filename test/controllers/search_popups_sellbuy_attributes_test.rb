require "test_helper"

class SearchPopupsSellbuyAttributesTest < ActionDispatch::IntegrationTest
  setup do
    post session_path, params: { email_address: "admin@example.com", password: "password" }

    StdCorporation.create!(
      corp_cd: "SPC01",
      corp_nm: "팝업테스트법인",
      indstype_cd: "업태",
      bizcond_cd: "업종",
      rptr_nm_cd: "대표자",
      use_yn_cd: "Y"
    )

    StdSellbuyAttribute.create!(
      corp_cd: "SPC01",
      sellbuy_sctn_cd: "SELL",
      sellbuy_attr_cd: "00009001",
      sellbuy_attr_nm: "팝업운송료",
      rdtn_nm: "운송",
      sellbuy_attr_eng_nm: "POPUP FREIGHT",
      tran_yn_cd: "Y",
      strg_yn_cd: "N",
      use_yn_cd: "Y"
    )
    StdSellbuyAttribute.create!(
      corp_cd: "SPC01",
      sellbuy_sctn_cd: "PUR",
      sellbuy_attr_cd: "00009002",
      sellbuy_attr_nm: "팝업보관료",
      rdtn_nm: "보관",
      sellbuy_attr_eng_nm: "POPUP STORAGE",
      tran_yn_cd: "N",
      strg_yn_cd: "Y",
      use_yn_cd: "Y"
    )
    StdSellbuyAttribute.create!(
      corp_cd: "SPC01",
      sellbuy_sctn_cd: "SELL",
      sellbuy_attr_cd: "00009999",
      sellbuy_attr_nm: "미사용항목",
      rdtn_nm: "미사용",
      sellbuy_attr_eng_nm: "INACTIVE ITEM",
      use_yn_cd: "N"
    )
  end

  test "sellbuy attribute popup html renders search fields" do
    get search_popup_path("sellbuy_attr")

    assert_response :success
    assert_includes response.body, "매출입항목코드"
    assert_includes response.body, "매출입항목명"
    assert_includes response.body, "운송여부"
    assert_includes response.body, "보관여부"
    assert_includes response.body, 'name="search_popup_form[sellbuy_attr_cd]"'
    assert_includes response.body, 'name="search_popup_form[sellbuy_attr_nm]"'
  end

  test "sellbuy attribute popup defaults use_yn to Y and filters rows" do
    get search_popup_path("sellbuy_attr"), params: { format: :json }

    assert_response :success
    rows = JSON.parse(response.body)
    codes = rows.map { |row| row["sellbuy_attr_cd"] || row["code"] }

    assert_includes codes, "00009001"
    assert_includes codes, "00009002"
    assert_not_includes codes, "00009999"
  end

  test "sellbuy attribute popup supports transport/storage filters" do
    get search_popup_path("sellbuy_attr"), params: {
      format: :json,
      search_popup_form: {
        corp_cd: "SPC01",
        tran_yn: "Y",
        strg_yn: "N",
        use_yn: "Y"
      }
    }

    assert_response :success
    rows = JSON.parse(response.body)
    assert_equal [ "00009001" ], rows.map { |row| row["sellbuy_attr_cd"] || row["code"] }
  end
end
