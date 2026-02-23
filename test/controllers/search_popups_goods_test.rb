require "test_helper"

class SearchPopupsGoodsTest < ActionDispatch::IntegrationTest
  setup do
    post session_path, params: { email_address: "admin@example.com", password: "password" }
  end

  test "good popup returns active goods rows" do
    StdGood.create!(goods_cd: "G100", goods_nm: "활성품명", use_yn_cd: "Y")
    StdGood.create!(goods_cd: "G200", goods_nm: "비활성품명", use_yn_cd: "N")

    get search_popup_path("good"), params: { format: :json }
    assert_response :success

    rows = JSON.parse(response.body)
    codes = rows.map { |row| row["code"] }
    assert_includes codes, "G100"
    assert_not_includes codes, "G200"
  end
end
