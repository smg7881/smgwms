require "test_helper"

class WmWorkplaceTest < ActiveSupport::TestCase
  test "valid with required fields" do
    workplace = WmWorkplace.new(
      workpl_cd: "WP01",
      workpl_nm: "메인 작업장",
      use_yn: "Y"
    )

    assert workplace.valid?
  end

  test "normalizes code fields before validation" do
    workplace = WmWorkplace.create!(
      workpl_cd: " wp01 ",
      workpl_nm: " 작업장A ",
      workpl_type: " wh ",
      nation_cd: " kr ",
      use_yn: " y "
    )

    assert_equal "WP01", workplace.workpl_cd
    assert_equal "작업장A", workplace.workpl_nm
    assert_equal "WH", workplace.workpl_type
    assert_equal "KR", workplace.nation_cd
    assert_equal "Y", workplace.use_yn
  end

  test "requires code and name" do
    workplace = WmWorkplace.new(workpl_cd: "", workpl_nm: "", use_yn: "Y")

    assert_not workplace.valid?
    assert_includes workplace.errors[:workpl_cd], "can't be blank"
    assert_includes workplace.errors[:workpl_nm], "can't be blank"
  end

  test "rejects invalid use_yn" do
    workplace = WmWorkplace.new(
      workpl_cd: "WP99",
      workpl_nm: "테스트",
      use_yn: "X"
    )

    assert_not workplace.valid?
    assert_includes workplace.errors[:use_yn], "is not included in the list"
  end
end
