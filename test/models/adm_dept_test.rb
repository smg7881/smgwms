require "test_helper"

class AdmDeptTest < ActiveSupport::TestCase
  setup do
    @hq = adm_depts(:hq)
    @sales = adm_depts(:sales_team)
    @cs = adm_depts(:cs_part)
  end

  test "fixture is valid" do
    assert @sales.valid?
  end

  test "requires dept_code and dept_nm" do
    dept = AdmDept.new
    refute dept.valid?
    assert_includes dept.errors[:dept_code], "can't be blank"
    assert_includes dept.errors[:dept_nm], "can't be blank"
  end

  test "validates use_yn inclusion" do
    @sales.use_yn = "Z"
    refute @sales.valid?
    assert_includes @sales.errors[:use_yn], "is not included in the list"
  end

  test "rejects missing parent dept" do
    dept = AdmDept.new(
      dept_code: "NEW1",
      dept_nm: "신규부서",
      parent_dept_code: "UNKNOWN",
      use_yn: "Y"
    )

    refute dept.valid?
    assert_includes dept.errors[:parent_dept_code], "상위 부서를 찾을 수 없습니다."
  end

  test "tree_ordered assigns level" do
    result = AdmDept.tree_ordered
    hq = result.find { |dept| dept.dept_code == "HQ" }
    sales = result.find { |dept| dept.dept_code == "SALES" }
    cs = result.find { |dept| dept.dept_code == "CS" }

    assert_equal 1, hq.dept_level
    assert_equal 2, sales.dept_level
    assert_equal 3, cs.dept_level
  end
end
