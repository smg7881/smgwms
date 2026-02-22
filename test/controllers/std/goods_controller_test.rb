require "test_helper"

class Std::GoodsControllerTest < ActionDispatch::IntegrationTest
  setup do
    post session_path, params: { email_address: "admin@example.com", password: "password" }
  end

  test "index responds to html and json" do
    StdGood.create!(goods_cd: "GD000001", goods_nm: "Goods A", use_yn_cd: "Y")

    get std_goods_url
    assert_response :success

    get std_goods_url(format: :json)
    assert_response :success
    rows = JSON.parse(response.body)
    assert rows.any? { |row| row["goods_cd"] == "GD000001" }
  end

  test "batch_save inserts updates and soft deletes" do
    StdGood.create!(goods_cd: "GD000010", goods_nm: "Before", use_yn_cd: "Y")
    StdGood.create!(goods_cd: "GD000011", goods_nm: "Delete", use_yn_cd: "Y")

    post batch_save_std_goods_url, params: {
      rowsToInsert: [{ goods_cd: "GD000012", goods_nm: "New Goods", use_yn_cd: "Y" }],
      rowsToUpdate: [{ goods_cd: "GD000010", goods_nm: "After", use_yn_cd: "Y" }],
      rowsToDelete: ["GD000011"]
    }, as: :json

    assert_response :success
    assert_equal "After", StdGood.find_by!(goods_cd: "GD000010").goods_nm
    assert_equal "N", StdGood.find_by!(goods_cd: "GD000011").use_yn_cd
    assert StdGood.exists?(goods_cd: "GD000012")
  end

  test "non-admin requires menu permission" do
    delete session_path
    user = User.find_by!(email_address: "user@example.com")
    AdmUserMenuPermission.where(user_id: user.id, menu_cd: "STD_GOODS").delete_all
    post session_path, params: { email_address: "user@example.com", password: "password" }

    get std_goods_url(format: :json)
    assert_response :forbidden

    AdmUserMenuPermission.create!(user: user, menu_cd: "STD_GOODS", use_yn: "Y")
    get std_goods_url(format: :json)
    assert_response :success
  end
end
