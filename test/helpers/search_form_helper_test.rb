require "test_helper"

class SearchFormHelperTest < ActionView::TestCase
  include SearchFormHelper

  test "sanitize_field_defs removes disallowed keys" do
    fields = [
      { field: "title", type: "input", malicious_key: "value" }
    ]
    sanitized = sanitize_field_defs(fields)
    assert_equal 1, sanitized.length
    assert_not sanitized.first.key?(:malicious_key)
    assert sanitized.first.key?(:field)
  end

  test "sanitize_field_defs normalizes type" do
    fields = [
      { field: "date", type: "date-picker" }
    ]
    sanitized = sanitize_field_defs(fields)
    assert_equal "date_picker", sanitized.first[:type]
  end

  test "span_classes_for handles different formats" do
    field_with_string = { span: "24 s:12 m:8" }
    assert_equal "form-grid-span-24 form-grid-span-sm-12 form-grid-span-md-8", span_classes_for(field_with_string, cols: 3)

    field_without_span = {}
    assert_equal "form-grid-span-24 form-grid-span-sm-12 form-grid-span-md-8", span_classes_for(field_without_span, cols: 3)
    assert_equal "form-grid-span-24 form-grid-span-sm-12 form-grid-span-md-6", span_classes_for(field_without_span, cols: 4)
  end

  test "resolve_label prioritizes label > label_key > humanized field" do
    assert_equal "Custom Label", resolve_label({ field: "title", label: "Custom Label" })
    # Mocking I18n would be ideal here, but testing the logic path involves ensuring precedence
    assert_equal "Title", resolve_label({ field: "title" })
  end

  test "sanitize_field_defs validates code_field for popup type" do
    fields = [
      { field: "customer_name", type: "popup" } # Missing code_field
    ]
    assert_raises(ArgumentError) do
      sanitize_field_defs(fields)
    end

    fields_valid = [
      { field: "customer_name", type: "popup", code_field: "customer_code" }
    ]
    assert_nothing_raised do
      sanitize_field_defs(fields_valid)
    end
  end
end
