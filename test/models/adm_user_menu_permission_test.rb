require "test_helper"

class AdmUserMenuPermissionTest < ActiveSupport::TestCase
  test "normalizes menu_cd and use_yn" do
    permission = AdmUserMenuPermission.create!(
      user: users(:admin),
      menu_cd: " wm_workplace ",
      use_yn: " y "
    )

    assert_equal "WM_WORKPLACE", permission.menu_cd
    assert_equal "Y", permission.use_yn
  end

  test "enforces uniqueness per user and menu" do
    AdmUserMenuPermission.create!(
      user: users(:admin),
      menu_cd: "SYS_MENU",
      use_yn: "Y"
    )

    duplicate = AdmUserMenuPermission.new(
      user: users(:admin),
      menu_cd: "SYS_MENU",
      use_yn: "Y"
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:menu_cd], "has already been taken"
  end
end
