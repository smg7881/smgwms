require "test_helper"

class AdmMenuTest < ActiveSupport::TestCase
  test "valid fixture" do
    assert adm_menus(:overview).valid?
  end

  test "menu type MENU requires menu_url" do
    menu = AdmMenu.new(
      menu_cd: "X1",
      menu_nm: "테스트",
      parent_cd: "MAIN",
      menu_level: 2,
      menu_type: "MENU",
      use_yn: "Y",
      sort_order: 1
    )

    assert_not menu.valid?
    assert_includes menu.errors[:menu_url], "메뉴 타입이 MENU일 때는 필수입니다."
  end

  test "parent must exist" do
    menu = AdmMenu.new(
      menu_cd: "X2",
      menu_nm: "테스트",
      parent_cd: "MISSING",
      menu_url: "/x2",
      menu_level: 2,
      menu_type: "MENU",
      use_yn: "Y",
      sort_order: 1
    )

    assert_not menu.valid?
    assert_includes menu.errors[:parent_cd], "상위 메뉴를 찾을 수 없습니다."
  end

  test "top level menu must have level 1" do
    menu = AdmMenu.new(
      menu_cd: "X3",
      menu_nm: "테스트",
      parent_cd: nil,
      menu_level: 2,
      menu_type: "FOLDER",
      use_yn: "Y",
      sort_order: 1
    )

    assert_not menu.valid?
    assert_includes menu.errors[:menu_level], "최상위 메뉴는 1이어야 합니다."
  end

  test "cannot self-parent" do
    menu = AdmMenu.new(
      menu_cd: "SELF",
      menu_nm: "자기참조",
      parent_cd: "SELF",
      menu_url: "/self",
      menu_level: 2,
      menu_type: "MENU",
      use_yn: "Y",
      sort_order: 1
    )

    assert_not menu.valid?
    assert_includes menu.errors[:parent_cd], "자기 자신을 부모로 지정할 수 없습니다."
  end
end
