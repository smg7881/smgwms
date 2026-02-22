require "test_helper"

class Ui::ResourceFormComponentTest < ViewComponent::TestCase
  test "renders with required attributes" do
    render_inline(Ui::ResourceFormComponent.new(
      model: Post.new,
      fields: [
        { field: "title", type: "input", label: "제목" }
      ]
    ))

    assert_selector '[data-controller~="resource-form"]'
    assert_selector ".bg-bg-secondary"
    assert_selector ".grid.grid-cols-24"
  end

  test "sanitizes disallowed field keys" do
    component = Ui::ResourceFormComponent.new(
      model: Post.new,
      fields: [
        { field: "title", type: "input", malicious_key: "value" }
      ]
    )

    render_inline(component)
    assert_selector '[data-controller~="resource-form"]'
  end

  test "normalizes field type from hyphen to underscore" do
    render_inline(Ui::ResourceFormComponent.new(
      model: Post.new,
      fields: [
        { field: "date", type: "date-picker" }
      ]
    ))

    assert_selector '[data-controller~="resource-form"]'
  end

  test "raises on unsupported field type" do
    assert_raises(ArgumentError) do
      render_inline(Ui::ResourceFormComponent.new(
        model: Post.new,
        fields: [
          { field: "title", type: "unsupported_type" }
        ]
      ))
    end
  end

  test "raises on invalid field name" do
    assert_raises(ArgumentError) do
      render_inline(Ui::ResourceFormComponent.new(
        model: Post.new,
        fields: [
          { field: "invalid field!", type: "input" }
        ]
      ))
    end
  end

  test "raises on blank field name" do
    assert_raises(ArgumentError) do
      render_inline(Ui::ResourceFormComponent.new(
        model: Post.new,
        fields: [
          { field: "", type: "input" }
        ]
      ))
    end
  end

  test "preserves allowed keys" do
    render_inline(Ui::ResourceFormComponent.new(
      model: Post.new,
      fields: [
        { field: "title", type: "input", label: "제목", required: true,
          placeholder: "입력하세요", span: "24", help: "도움말" }
      ]
    ))

    assert_selector '[data-controller~="resource-form"]'
  end

  test "all field types are supported" do
    types = %w[input number select date_picker textarea checkbox radio switch]
    types.each do |type|
      assert_nothing_raised do
        Ui::ResourceFormComponent.new(
          model: Post.new,
          fields: [ { field: "test_field", type: type } ]
        )
      end
    end
  end

  test "extracts dependencies" do
    render_inline(Ui::ResourceFormComponent.new(
      model: Post.new,
      fields: [
        { field: "company_cd", type: "select" },
        { field: "warehouse_cd", type: "select", depends_on: "company_cd", depends_filter: "company_cd" }
      ]
    ))

    assert_selector "[data-resource-form-dependencies-value]"
    html = rendered_content
    assert_includes html, "warehouse_cd"
    assert_includes html, "company_cd"
  end

  test "shows error messages when model has errors" do
    post = Post.new
    post.errors.add(:title, "을(를) 입력해주세요")

    render_inline(Ui::ResourceFormComponent.new(
      model: post,
      fields: [ { field: "title", type: "input" } ]
    ))

    assert_selector ".bg-accent-rose\\/10"
    assert_text "을(를) 입력해주세요"
  end

  test "hides buttons when show_buttons is false" do
    render_inline(Ui::ResourceFormComponent.new(
      model: Post.new,
      fields: [ { field: "title", type: "input" } ],
      show_buttons: false
    ))

    assert_no_selector ".form-grid-btn-group"
  end

  test "merges custom data and controller attributes" do
    render_inline(Ui::ResourceFormComponent.new(
      model: Post.new,
      fields: [ { field: "title", type: "input" } ],
      data: { controller: "my-ctrl", my_target: "form" }
    ))

    assert_selector '[data-controller="my-ctrl resource-form"]'
    assert_selector '[data-my-target="form"]'
  end

  test "merges form_data into form element" do
    render_inline(Ui::ResourceFormComponent.new(
      model: Post.new,
      fields: [ { field: "title", type: "input" } ],
      form_data: { my_target: "form" }
    ))

    assert_selector "form[data-my-target='form']"
  end

  test "supports custom form method" do
    render_inline(Ui::ResourceFormComponent.new(
      model: Post.new,
      fields: [ { field: "title", type: "input" } ],
      method: :get
    ))

    assert_selector "form[method='get']"
  end
end
