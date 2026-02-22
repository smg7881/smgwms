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
  end

  test "html renders resource form and ag-grid popup layout" do
    get search_popup_path("country"), params: { q: "테스트" }

    assert_response :success
    assert_includes response.body, 'data-controller="search-popup-grid"'
    assert_includes response.body, 'data-controller="ag-grid"'
    assert_includes response.body, 'name="search_popup_form[display]"'
  end

  test "json response includes code and name fields" do
    get search_popup_path("country"), params: { q: "테스트", format: :json }

    assert_response :success
    rows = JSON.parse(response.body)
    assert_equal 1, rows.length
    assert_equal "TP01", rows.first["code"]
    assert_equal "테스트국", rows.first["name"]
    assert_equal "테스트국", rows.first["display"]
  end

  test "keyword from popup form params is applied" do
    get search_popup_path("country"), params: {
      format: :json,
      search_popup_form: { display: "다른" }
    }

    assert_response :success
    rows = JSON.parse(response.body)
    assert_equal [ "OT99" ], rows.map { |row| row["code"] }
  end
end
