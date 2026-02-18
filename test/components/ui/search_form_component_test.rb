require "test_helper"

class Ui::SearchFormComponentTest < ViewComponent::TestCase
  test "renders with required attributes" do
    render_inline(Ui::SearchFormComponent.new(
      url: "/posts",
      fields: [
        { field: "title", type: "input", label: "제목" }
      ]
    ))

    assert_selector '[data-controller="search-form"]'
    assert_selector ".bg-bg-secondary"
    assert_selector ".grid.grid-cols-24"
  end

  test "applies stimulus data attributes" do
    render_inline(Ui::SearchFormComponent.new(
      url: "/posts",
      fields: [ { field: "title", type: "input" } ],
      cols: 4,
      enable_collapse: false,
      collapsed_rows: 2
    ))

    assert_selector '[data-search-form-cols-value="4"]'
    assert_selector '[data-search-form-enable-collapse-value="false"]'
    assert_selector '[data-search-form-collapsed-rows-value="2"]'
  end

  test "sanitizes disallowed field keys" do
    component = Ui::SearchFormComponent.new(
      url: "/posts",
      fields: [
        { field: "title", type: "input", malicious_key: "value" }
      ]
    )

    # Should not raise — disallowed keys are simply stripped
    render_inline(component)
    assert_selector '[data-controller="search-form"]'
  end

  test "normalizes field type from hyphen to underscore" do
    render_inline(Ui::SearchFormComponent.new(
      url: "/posts",
      fields: [
        { field: "date", type: "date-picker" }
      ]
    ))

    assert_selector '[data-controller="search-form"]'
  end

  test "raises on invalid field name" do
    assert_raises(ArgumentError) do
      render_inline(Ui::SearchFormComponent.new(
        url: "/posts",
        fields: [
          { field: "invalid field!", type: "input" }
        ]
      ))
    end
  end

  test "raises on unsupported field type" do
    assert_raises(ArgumentError) do
      render_inline(Ui::SearchFormComponent.new(
        url: "/posts",
        fields: [
          { field: "title", type: "unsupported" }
        ]
      ))
    end
  end

  test "raises when popup field missing code_field" do
    assert_raises(ArgumentError) do
      render_inline(Ui::SearchFormComponent.new(
        url: "/posts",
        fields: [
          { field: "customer_name", type: "popup" }
        ]
      ))
    end
  end

  test "accepts popup field with code_field" do
    assert_nothing_raised do
      render_inline(Ui::SearchFormComponent.new(
        url: "/posts",
        fields: [
          { field: "customer_name", type: "popup", code_field: "customer_code" }
        ]
      ))
    end
  end

  test "hides buttons when show_buttons is false" do
    render_inline(Ui::SearchFormComponent.new(
      url: "/posts",
      fields: [ { field: "title", type: "input" } ],
      show_buttons: false
    ))

    assert_no_selector ".form-grid-btn-group"
  end

  test "merges custom data attributes" do
    render_inline(Ui::SearchFormComponent.new(
      url: "/posts",
      fields: [ { field: "title", type: "input" } ],
      data: { my_target: "search" }
    ))

    assert_selector '[data-my-target="search"]'
    assert_selector '[data-controller="search-form"]'
  end

  test "applies default values" do
    render_inline(Ui::SearchFormComponent.new(
      url: "/posts",
      fields: [ { field: "title", type: "input" } ]
    ))

    assert_selector '[data-search-form-cols-value="3"]'
    assert_selector '[data-search-form-enable-collapse-value="true"]'
    assert_selector '[data-search-form-collapsed-rows-value="1"]'
  end
end
