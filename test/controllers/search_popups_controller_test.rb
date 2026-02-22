require "test_helper"

class SearchPopupsControllerTest < ActionDispatch::IntegrationTest
  setup do
    post session_path, params: { email_address: "admin@example.com", password: "password" }

    StdCountry.create!(
      ctry_cd: "TP01",
      ctry_nm: "테스트국",
      ctry_eng_nm: "Testland",
      ctry_ar_cd: "TST",
      use_yn_cd: "Y"
    )

    StdCountry.create!(
      ctry_cd: "OT99",
      ctry_nm: "다른국",
      ctry_eng_nm: "Otherland",
      ctry_ar_cd: "OTH",
      use_yn_cd: "Y"
    )

    StdCorporation.create!(
      corp_cd: "ZCP01",
      corp_nm: "테스트법인 본사",
      indstype_cd: "업태",
      bizcond_cd: "종목",
      rptr_nm_cd: "대표자",
      compreg_slip_cd: "111-11-11111",
      use_yn_cd: "Y"
    )
    StdCorporation.create!(
      corp_cd: "ZCP02",
      corp_nm: "테스트법인 지사",
      indstype_cd: "업태",
      bizcond_cd: "종목",
      rptr_nm_cd: "대표자",
      upper_corp_cd: "ZCP01",
      compreg_slip_cd: "222-22-22222",
      use_yn_cd: "Y"
    )
    StdCorporation.create!(
      corp_cd: "ZCP99",
      corp_nm: "비사용법인",
      indstype_cd: "업태",
      bizcond_cd: "종목",
      rptr_nm_cd: "대표자",
      compreg_slip_cd: "999-99-99999",
      use_yn_cd: "N"
    )

    StdCorporationCountry.create!(
      corp_cd: "ZCP01",
      ctry_cd: "KR",
      rpt_yn_cd: "Y",
      use_yn_cd: "Y"
    )
    StdCorporationCountry.create!(
      corp_cd: "ZCP02",
      ctry_cd: "US",
      rpt_yn_cd: "Y",
      use_yn_cd: "Y"
    )
  end

  test "country popup html renders common popup layout" do
    get search_popup_path("country"), params: { q: "테스트" }

    assert_response :success
    assert_includes response.body, 'data-controller="search-popup-grid"'
    assert_includes response.body, 'data-controller="ag-grid"'
    assert_includes response.body, 'name="search_popup_form[display]"'
  end

  test "country popup json includes code and name fields" do
    get search_popup_path("country"), params: { q: "테스트", format: :json }

    assert_response :success
    rows = JSON.parse(response.body)
    assert_equal 1, rows.length
    assert_equal "TP01", rows.first["code"]
    assert_equal "테스트국", rows.first["name"]
    assert_equal "테스트국", rows.first["display"]
  end

  test "country popup applies keyword from popup form display field" do
    get search_popup_path("country"), params: {
      format: :json,
      search_popup_form: { display: "다른" }
    }

    assert_response :success
    rows = JSON.parse(response.body)
    assert_equal [ "OT99" ], rows.map { |row| row["code"] }
  end

  test "corp popup html renders PRD search fields" do
    get search_popup_path("corp")

    assert_response :success
    assert_includes response.body, 'name="search_popup_form[corp_cd]"'
    assert_includes response.body, 'name="search_popup_form[corp_nm]"'
    assert_includes response.body, 'name="search_popup_form[use_yn]"'
    assert_includes response.body, "법인코드"
    assert_includes response.body, "사업자등록번호"
  end

  test "corp popup defaults use_yn to Y and excludes N rows" do
    get search_popup_path("corp"), params: { format: :json }

    assert_response :success
    rows = JSON.parse(response.body)
    codes = rows.map { |row| row["corp_cd"] || row["code"] }
    assert_includes codes, "ZCP01"
    assert_includes codes, "ZCP02"
    assert_not_includes codes, "ZCP99"

    branch = rows.find { |row| row["corp_cd"] == "ZCP02" }
    assert_equal "ZCP01", branch["upper_corp_cd"]
    assert_equal "테스트법인 본사", branch["upper_corp_nm"]
  end

  test "corp popup filters by corp_cd and corp_nm and returns PRD columns" do
    get search_popup_path("corp"), params: {
      format: :json,
      search_popup_form: { corp_cd: "P01", corp_nm: "본사", use_yn: "Y" }
    }

    assert_response :success
    rows = JSON.parse(response.body)
    assert_equal 1, rows.length
    assert_equal "ZCP01", rows.first["corp_cd"]
    assert_equal "테스트법인 본사", rows.first["corp_nm"]
    assert_equal "KR", rows.first["ctry"]
    assert_equal "111-11-11111", rows.first["biz_no"]
  end
end
