require "test_helper"

class Std::FavoritesControllerTest < ActionDispatch::IntegrationTest
  setup do
    post session_path, params: { email_address: "admin@example.com", password: "password" }
  end

  test "index and groups return favorite rows for selected user" do
    StdUserFavorite.create!(
      user_id_code: "USER01",
      menu_cd: "SYS_MENU",
      menu_nm: "Menu Management",
      user_favor_menu_grp: "BASE",
      sort_seq: 1,
      use_yn: "Y"
    )
    StdUserFavoriteGroup.create!(
      user_id_code: "USER01",
      group_nm: "BASE",
      use_yn: "Y"
    )

    get std_favorites_url(format: :json, q: { user_id_code: "USER01" })
    assert_response :success
    rows = JSON.parse(response.body)
    assert rows.any? { |row| row["menu_cd"] == "SYS_MENU" }

    get groups_std_favorites_url(format: :json, q: { user_id_code: "USER01" })
    assert_response :success
    groups = JSON.parse(response.body)
    assert groups.any? { |row| row["group_nm"] == "BASE" }
  end

  test "batch_save and batch_save_groups support insert update delete" do
    StdUserFavorite.create!(
      user_id_code: "USER01",
      menu_cd: "SYS_MENU",
      menu_nm: "Menu Management",
      user_favor_menu_grp: "OLD",
      sort_seq: 1,
      use_yn: "Y"
    )
    StdUserFavoriteGroup.create!(
      user_id_code: "USER01",
      group_nm: "OLD",
      use_yn: "Y"
    )

    post batch_save_std_favorites_url, params: {
      rowsToInsert: [{ user_id_code: "USER01", menu_cd: "OVERVIEW", menu_nm: "Overview", user_favor_menu_grp: "NEW", sort_seq: 2, use_yn: "Y" }],
      rowsToUpdate: [{ user_id_code: "USER01", menu_cd: "SYS_MENU", menu_nm: "Menu Management", user_favor_menu_grp: "NEW", sort_seq: 9, use_yn: "Y" }],
      rowsToDelete: [{ user_id_code: "USER01", menu_cd: "SYS_MENU" }]
    }, as: :json
    assert_response :success
    assert_equal "N", StdUserFavorite.find_by!(user_id_code: "USER01", menu_cd: "SYS_MENU").use_yn
    assert StdUserFavorite.exists?(user_id_code: "USER01", menu_cd: "OVERVIEW")

    post batch_save_groups_std_favorites_url, params: {
      rowsToInsert: [{ user_id_code: "USER01", group_nm: "NEW", use_yn: "Y" }],
      rowsToUpdate: [{ user_id_code: "USER01", group_nm: "OLD", use_yn: "Y" }],
      rowsToDelete: [{ user_id_code: "USER01", group_nm: "OLD" }]
    }, as: :json
    assert_response :success
    assert_equal "N", StdUserFavoriteGroup.find_by!(user_id_code: "USER01", group_nm: "OLD").use_yn
    assert StdUserFavoriteGroup.exists?(user_id_code: "USER01", group_nm: "NEW")
  end

  test "non-admin requires menu permission" do
    delete session_path
    user = User.find_by!(email_address: "user@example.com")
    AdmUserMenuPermission.where(user_id: user.id, menu_cd: "STD_FAVORITE").delete_all
    post session_path, params: { email_address: "user@example.com", password: "password" }

    get std_favorites_url(format: :json)
    assert_response :forbidden

    AdmUserMenuPermission.create!(user: user, menu_cd: "STD_FAVORITE", use_yn: "Y")
    get std_favorites_url(format: :json)
    assert_response :success
  end
end
