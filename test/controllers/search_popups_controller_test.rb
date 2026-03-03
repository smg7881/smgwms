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

    AdmDept.create!(
      dept_code: "ZDPT01",
      dept_nm: "물류부",
      dept_order: 1,
      use_yn: "Y"
    )

    StdZipCode.create!(
      ctry_cd: "KR",
      zipcd: "99123",
      seq_no: 1,
      zipaddr: "서울특별시 강남구 테헤란로",
      use_yn_cd: "Y"
    )

    StdFinancialInstitution.create!(
      fnc_or_cd: "KDB",
      fnc_or_nm: "산업은행",
      fnc_or_eng_nm: "KOREA DEVELOPMENT BANK",
      ctry_cd: "KR",
      ctry_nm: "대한민국",
      use_yn_cd: "Y"
    )
    StdFinancialInstitution.create!(
      fnc_or_cd: "WBK",
      fnc_or_nm: "월드뱅크",
      fnc_or_eng_nm: "WORLD BANK",
      ctry_cd: "US",
      ctry_nm: "미국",
      use_yn_cd: "Y"
    )
    StdFinancialInstitution.create!(
      fnc_or_cd: "OLD",
      fnc_or_nm: "비사용금융기관",
      fnc_or_eng_nm: "OLD BANK",
      ctry_cd: "KR",
      ctry_nm: "대한민국",
      use_yn_cd: "N"
    )

    AdmCodeHeader.find_or_create_by!(code: "03") do |row|
      row.code_name = "거래처구분그룹"
      row.use_yn = "Y"
    end
    AdmCodeHeader.find_or_create_by!(code: "04") do |row|
      row.code_name = "거래처구분"
      row.use_yn = "Y"
    end
    AdmCodeDetail.find_or_create_by!(code: "03", detail_code: "10") do |row|
      row.detail_code_name = "고객(화주)"
      row.sort_order = 1
      row.use_yn = "Y"
    end
    AdmCodeDetail.find_or_create_by!(code: "03", detail_code: "20") do |row|
      row.detail_code_name = "협력사"
      row.sort_order = 2
      row.use_yn = "Y"
    end
    AdmCodeDetail.find_or_create_by!(code: "04", detail_code: "10") do |row|
      row.detail_code_name = "국내화주고객"
      row.sort_order = 1
      row.use_yn = "Y"
    end
    AdmCodeDetail.find_or_create_by!(code: "04", detail_code: "70") do |row|
      row.detail_code_name = "운송사"
      row.sort_order = 2
      row.use_yn = "Y"
    end

    StdBzacMst.create!(
      bzac_cd: "BZC001",
      bzac_nm: "테스트거래처 본사",
      mngt_corp_cd: "ZCP01",
      bizman_no: "8881234567",
      bzac_sctn_grp_cd: "10",
      bzac_sctn_cd: "10",
      bzac_kind_cd: "CORP",
      ctry_cd: "KR",
      rpt_sales_emp_cd: "SALE01",
      aply_strt_day_cd: Date.new(2026, 1, 1),
      use_yn_cd: "Y",
      bilg_bzac_cd: "BIL001"
    )
    StdBzacMst.create!(
      bzac_cd: "BZC002",
      bzac_nm: "테스트거래처 지사",
      mngt_corp_cd: "ZCP01",
      bizman_no: "8881234568",
      bzac_sctn_grp_cd: "20",
      bzac_sctn_cd: "70",
      bzac_kind_cd: "CORP",
      ctry_cd: "KR",
      rpt_sales_emp_cd: "SALE02",
      aply_strt_day_cd: Date.new(2026, 1, 1),
      rpt_bzac_cd: "BZC001",
      use_yn_cd: "Y"
    )
    StdBzacMst.create!(
      bzac_cd: "BZC999",
      bzac_nm: "비사용거래처",
      mngt_corp_cd: "ZCP01",
      bizman_no: "8881234569",
      bzac_sctn_grp_cd: "10",
      bzac_sctn_cd: "10",
      bzac_kind_cd: "CORP",
      ctry_cd: "KR",
      rpt_sales_emp_cd: "SALE99",
      aply_strt_day_cd: Date.new(2026, 1, 1),
      use_yn_cd: "N"
    )

    StdBzacOfcr.create!(
      bzac_cd: "BZC001",
      seq_cd: 1,
      nm_cd: "담당자A",
      ofic_telno_cd: "02-111-2222",
      rpt_yn_cd: "Y",
      use_yn_cd: "Y"
    )
    StdBzacOfcr.create!(
      bzac_cd: "BZC002",
      seq_cd: 1,
      nm_cd: "담당자B",
      ofic_telno_cd: "02-333-4444",
      rpt_yn_cd: "Y",
      use_yn_cd: "Y"
    )
  end

  test "country popup html renders common popup layout" do
    get search_popup_path("country"), params: { q: "테스트" }

    assert_response :success
    assert_includes response.body, 'data-controller="search-popup-grid"'
    assert_includes response.body, 'data-controller="ag-grid"'
    assert_includes response.body, 'name="q[display]"'
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
      q: { display: "다른" }
    }

    assert_response :success
    rows = JSON.parse(response.body)
    assert_equal [ "OT99" ], rows.map { |row| row["code"] }
  end

  test "corp popup html renders PRD search fields" do
    get search_popup_path("corp")

    assert_response :success
    assert_includes response.body, 'name="q[corp_cd]"'
    assert_includes response.body, 'name="q[corp_nm]"'
    assert_includes response.body, 'name="q[use_yn]"'
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
      q: { corp_cd: "P01", corp_nm: "본사", use_yn: "Y" }
    }

    assert_response :success
    rows = JSON.parse(response.body)
    assert_equal 1, rows.length
    assert_equal "ZCP01", rows.first["corp_cd"]
    assert_equal "테스트법인 본사", rows.first["corp_nm"]
    assert_equal "KR", rows.first["ctry"]
    assert_equal "111-11-11111", rows.first["biz_no"]
  end

  test "dept popup returns active departments" do
    get search_popup_path("dept"), params: { format: :json, q: "물류" }

    assert_response :success
    rows = JSON.parse(response.body)
    assert_equal 1, rows.length
    assert_equal "ZDPT01", rows.first["code"]
    assert_equal "물류부", rows.first["name"]
  end

  test "zipcode popup returns zipcode and address" do
    get search_popup_path("zipcode"), params: { format: :json, q: "99123" }

    assert_response :success
    rows = JSON.parse(response.body)
    assert_equal 1, rows.length
    assert_equal "99123", rows.first["code"]
    assert_includes rows.first["name"], "강남구"
  end

  test "financial institution popup html renders PRD search fields" do
    get search_popup_path("financial_institution")

    assert_response :success
    assert_includes response.body, 'name="q[ctry_cd]"'
    assert_includes response.body, 'name="q[fnc_or_cd]"'
    assert_includes response.body, 'name="q[fnc_or_nm]"'
    assert_includes response.body, 'name="q[use_yn]"'
    assert_includes response.body, "금융기관코드"
    assert_includes response.body, "금융기관영문명"
  end

  test "financial institution popup defaults use_yn to Y and filters rows" do
    get search_popup_path("financial_institution"), params: {
      format: :json,
      q: { ctry_cd: "KR", fnc_or_nm: "산업", use_yn: "Y" }
    }

    assert_response :success
    rows = JSON.parse(response.body)
    assert_equal 1, rows.length
    assert_equal "KDB", rows.first["code"]
    assert_equal "산업은행", rows.first["name"]
    assert_equal "KDB", rows.first["fnc_or_cd"]
    assert_equal "KOREA DEVELOPMENT BANK", rows.first["fnc_or_eng_nm"]
    assert_equal "대한민국", rows.first["ctry_nm"]
    assert_equal "Y", rows.first["use_yn"]
  end

  test "financial institution popup alias fin_org works" do
    get search_popup_path("fin_org"), params: { format: :json, q: "world" }

    assert_response :success
    rows = JSON.parse(response.body)
    assert_equal 1, rows.length
    assert_equal "WBK", rows.first["code"]
    assert_equal "월드뱅크", rows.first["name"]
  end

  test "customer popup html renders DS02 search fields" do
    get search_popup_path("customer")

    assert_response :success
    assert_includes response.body, 'name="q[bzac_cd]"'
    assert_includes response.body, 'name="q[bzac_nm]"'
    assert_includes response.body, 'name="q[corp_nm]"'
    assert_includes response.body, 'name="q[head_office_yn]"'
    assert_includes response.body, 'name="q[bzac_sctn_grp_cd]"'
    assert_includes response.body, 'name="q[bzac_sctn_cd]"'
    assert_includes response.body, 'name="q[use_yn]"'
    assert_includes response.body, 'name="q[biz_no]"'
    assert_includes response.body, "담당자명"
    assert_includes response.body, "청구거래처코드"
  end

  test "customer popup json returns DS02 columns and applies filters" do
    get search_popup_path("customer"), params: {
      format: :json,
      q: {
        corp_cd: "ZCP01",
        head_office_yn: "Y",
        bzac_sctn_grp_cd: "10",
        bzac_sctn_cd: "10",
        biz_no: "888-123-4567",
        use_yn: "Y"
      }
    }

    assert_response :success
    rows = JSON.parse(response.body)
    assert_equal 1, rows.length
    assert_equal "BZC001", rows.first["bzac_cd"]
    assert_equal "테스트거래처 본사", rows.first["bzac_nm"]
    assert_equal "888-123-4567", rows.first["biz_no"]
    assert_equal "국내화주고객", rows.first["bzac_sctn"]
    assert_equal "담당자A", rows.first["ofcr_nm"]
    assert_equal "02-111-2222", rows.first["tel_no"]
    assert_equal "BIL001", rows.first["bilg_bzac_cd"]
    assert_equal "Y", rows.first["head_office_yn"]
  end
end
