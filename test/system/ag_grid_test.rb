require "application_system_test_case"

class AgGridTest < ApplicationSystemTestCase
  test "posts index renders AG Grid" do
    Post.create!(title: "테스트", content: "내용")
    visit posts_path

    assert_selector "[data-controller='ag-grid']"
    assert_selector ".ag-root-wrapper", wait: 10
    assert_text "테스트", wait: 10
  end

  test "AG Grid survives Turbo navigation round-trip" do
    Post.create!(title: "왕복테스트", content: "내용")
    visit posts_path
    assert_selector ".ag-root-wrapper", wait: 10

    visit root_path
    go_back
    assert_selector ".ag-root-wrapper", wait: 10
    assert_text "왕복테스트", wait: 10
  end
end
