require "test_helper"

class ResourceFormHelperTest < ActionView::TestCase
  include ResourceFormHelper
  include SearchFormHelper

  test "sanitize_resource_field_defs removes disallowed keys" do
    fields = [
      { field: "title", type: "input", malicious_key: "value" }
    ]
    sanitized = sanitize_resource_field_defs(fields)
    assert_equal 1, sanitized.length
    assert_not sanitized.first.key?(:malicious_key)
    assert sanitized.first.key?(:field)
  end

  test "sanitize_resource_field_defs normalizes type" do
    fields = [
      { field: "date", type: "date-picker" }
    ]
    sanitized = sanitize_resource_field_defs(fields)
    assert_equal "date_picker", sanitized.first[:type]
  end

  test "sanitize_resource_field_defs rejects unsupported types" do
    fields = [
      { field: "title", type: "unsupported_type" }
    ]
    assert_raises(ArgumentError) do
      sanitize_resource_field_defs(fields)
    end
  end

  test "sanitize_resource_field_defs validates field name" do
    fields = [
      { field: "invalid field!", type: "input" }
    ]
    assert_raises(ArgumentError) do
      sanitize_resource_field_defs(fields)
    end
  end

  test "sanitize_resource_field_defs rejects blank field name" do
    fields = [
      { field: "", type: "input" }
    ]
    assert_raises(ArgumentError) do
      sanitize_resource_field_defs(fields)
    end
  end

  test "sanitize_resource_field_defs preserves allowed keys" do
    fields = [
      { field: "title", type: "input", label: "제목", required: true,
        placeholder: "입력하세요", span: "24", help: "도움말" }
    ]
    sanitized = sanitize_resource_field_defs(fields)
    result = sanitized.first

    assert_equal "title", result[:field]
    assert_equal "input", result[:type]
    assert_equal "제목", result[:label]
    assert_equal true, result[:required]
    assert_equal "입력하세요", result[:placeholder]
    assert_equal "24", result[:span]
    assert_equal "도움말", result[:help]
  end

  test "extract_dependencies builds dependency map" do
    fields = [
      { field: "company_cd", type: "select" },
      { field: "warehouse_cd", type: "select", depends_on: "company_cd", depends_filter: "company_cd" }
    ]
    safe_fields = sanitize_resource_field_defs(fields)
    deps = extract_dependencies(safe_fields)

    assert_equal 1, deps.size
    assert deps.key?("warehouse_cd")
    assert_equal "company_cd", deps["warehouse_cd"][:parent]
    assert_equal "company_cd", deps["warehouse_cd"][:filter_key]
  end

  test "extract_dependencies returns empty hash when no dependencies" do
    fields = [
      { field: "title", type: "input" },
      { field: "content", type: "textarea" }
    ]
    safe_fields = sanitize_resource_field_defs(fields)
    deps = extract_dependencies(safe_fields)

    assert_equal({}, deps)
  end

  test "all 8 field types are supported" do
    types = %w[input number select date_picker textarea checkbox radio switch]
    types.each do |type|
      fields = [ { field: "test_field", type: type } ]
      sanitized = sanitize_resource_field_defs(fields)
      assert_equal type, sanitized.first[:type], "Type '#{type}' should be supported"
    end
  end

  test "span_classes_for works with resource form fields" do
    field_with_span = { span: "24 s:12 m:8" }
    assert_equal "form-grid-span-24 form-grid-span-sm-12 form-grid-span-md-8", span_classes_for(field_with_span, cols: 3)

    field_without_span = {}
    assert_equal "form-grid-span-24 form-grid-span-sm-12 form-grid-span-md-8", span_classes_for(field_without_span, cols: 3)
  end
end
