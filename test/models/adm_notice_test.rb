require "test_helper"

class AdmNoticeTest < ActiveSupport::TestCase
  test "requires category_code, title and content" do
    notice = AdmNotice.new

    refute notice.valid?
    assert_includes notice.errors[:category_code], "can't be blank"
    assert_includes notice.errors[:title], "can't be blank"
    assert_includes notice.errors[:content], "can't be blank"
  end

  test "validates yn fields" do
    notice = AdmNotice.new(
      category_code: "GENERAL",
      title: "공지",
      content: "내용",
      is_top_fixed: "X",
      is_published: "Y"
    )

    refute notice.valid?
    assert_includes notice.errors[:is_top_fixed], "is not included in the list"
  end

  test "validates end_date after start_date" do
    notice = AdmNotice.new(
      category_code: "GENERAL",
      title: "공지",
      content: "내용",
      is_top_fixed: "N",
      is_published: "Y",
      start_date: Date.current,
      end_date: Date.current - 1.day
    )

    refute notice.valid?
    assert_includes notice.errors[:end_date], "must be on or after start_date"
  end

  test "normalizes fields" do
    notice = AdmNotice.create!(
      category_code: " general ",
      title: "  제목  ",
      content: "  내용  ",
      is_top_fixed: "y",
      is_published: "n"
    )

    assert_equal "GENERAL", notice.category_code
    assert_equal "제목", notice.title
    assert_equal "내용", notice.content
    assert_equal "Y", notice.is_top_fixed
    assert_equal "N", notice.is_published
  end
end
