require "test_helper"

class Std::ExchangeRatesControllerTest < ActionDispatch::IntegrationTest
  setup do
    post session_path, params: { email_address: "admin@example.com", password: "password" }
  end

  test "index html redirects to default search and json responds" do
    get std_exchange_rates_url
    assert_response :redirect
    assert_match("q%5Bctry_cd%5D=KR", response.location)

    get std_exchange_rates_url(format: :json)
    assert_response :success
  end

  test "batch_save inserts updates and soft deletes using composite key" do
    StdExchangeRate.create!(
      ctry_cd: "KR",
      fnc_or_cd: "KDB",
      std_ymd: Date.current,
      anno_dgrcnt: "FIRST",
      mon_cd: "USD",
      tradg_std_rt: 1300.0,
      use_yn_cd: "Y"
    )
    StdExchangeRate.create!(
      ctry_cd: "KR",
      fnc_or_cd: "KDB",
      std_ymd: Date.current,
      anno_dgrcnt: "FIRST",
      mon_cd: "JPY",
      tradg_std_rt: 9.0,
      use_yn_cd: "Y"
    )

    post batch_save_std_exchange_rates_url, params: {
      rowsToInsert: [
        {
          ctry_cd: "KR",
          fnc_or_cd: "KDB",
          std_ymd: Date.current,
          anno_dgrcnt: "FIRST",
          mon_cd: "EUR",
          tradg_std_rt: 1400.0,
          use_yn_cd: "Y"
        }
      ],
      rowsToUpdate: [
        {
          ctry_cd: "KR",
          fnc_or_cd: "KDB",
          std_ymd: Date.current,
          anno_dgrcnt: "FIRST",
          mon_cd: "USD",
          tradg_std_rt: 1350.0,
          use_yn_cd: "Y"
        }
      ],
      rowsToDelete: [
        {
          ctry_cd: "KR",
          fnc_or_cd: "KDB",
          std_ymd: Date.current,
          anno_dgrcnt: "FIRST",
          mon_cd: "JPY"
        }
      ]
    }, as: :json

    assert_response :success
    assert_equal BigDecimal("1350.0"), StdExchangeRate.find_by!(ctry_cd: "KR", fnc_or_cd: "KDB", std_ymd: Date.current, anno_dgrcnt: "FIRST", mon_cd: "USD").tradg_std_rt
    assert_equal "N", StdExchangeRate.find_by!(ctry_cd: "KR", fnc_or_cd: "KDB", std_ymd: Date.current, anno_dgrcnt: "FIRST", mon_cd: "JPY").use_yn_cd
    assert StdExchangeRate.exists?(ctry_cd: "KR", fnc_or_cd: "KDB", std_ymd: Date.current, anno_dgrcnt: "FIRST", mon_cd: "EUR")
  end

  test "non-admin requires menu permission" do
    delete session_path
    user = User.find_by!(email_address: "user@example.com")
    AdmUserMenuPermission.where(user_id: user.id, menu_cd: "STD_EXCHANGE_RATE").delete_all
    post session_path, params: { email_address: "user@example.com", password: "password" }

    get std_exchange_rates_url(format: :json)
    assert_response :forbidden

    AdmUserMenuPermission.create!(user: user, menu_cd: "STD_EXCHANGE_RATE", use_yn: "Y")
    get std_exchange_rates_url(format: :json)
    assert_response :success
  end
end
