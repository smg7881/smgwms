require "test_helper"

class AdmRoleTest < ActiveSupport::TestCase
  test "requires role_cd and role_nm" do
    role = AdmRole.new

    refute role.valid?
    assert_includes role.errors[:role_cd], "can't be blank"
    assert_includes role.errors[:role_nm], "can't be blank"
  end

  test "validates use_yn inclusion" do
    role = AdmRole.new(role_cd: "MANAGER", role_nm: "관리자", use_yn: "Z")

    refute role.valid?
    assert_includes role.errors[:use_yn], "is not included in the list"
  end

  test "normalizes role_cd and use_yn" do
    role = AdmRole.create!(role_cd: " manager ", role_nm: "관리자", use_yn: "y")

    assert_equal "MANAGER", role.role_cd
    assert_equal "Y", role.use_yn
  end
end
