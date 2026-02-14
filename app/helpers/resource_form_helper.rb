module ResourceFormHelper
  RESOURCE_ALLOWED_FIELD_KEYS = %i[
    field type label label_key placeholder placeholder_key
    span options required disabled readonly value target
    pattern minlength maxlength inputmode autocomplete
    date_type min max step
    rows cols
    include_blank help
    depends_on depends_filter
    input_type
  ].freeze

  RESOURCE_VALID_FIELD_NAME = /\A[a-zA-Z0-9_]+\z/

  RESOURCE_FIELD_TYPES = %w[
    input number select date_picker
    textarea checkbox radio switch
  ].freeze

  def resource_form_tag(model:, fields:, url: nil, cols: 3,
                        show_buttons: true, submit_label: "저장",
                        cancel_url: nil, form_data: {}, form_html: {}, **html_options)
    safe_fields = sanitize_resource_field_defs(fields)
    dependencies = extract_dependencies(safe_fields)
    wrapper_options = build_wrapper_options(html_options, dependencies)

    render partial: "shared/resource_form/form", locals: {
      model: model,
      fields: safe_fields,
      url: url,
      cols: cols,
      show_buttons: show_buttons,
      submit_label: submit_label,
      cancel_url: cancel_url,
      form_data: form_data,
      form_html: form_html,
      wrapper_options: wrapper_options
    }
  end

  private
    def build_wrapper_options(html_options, dependencies)
      options = html_options.deep_dup
      data = (options.delete(:data) || {}).deep_dup

      data[:controller] = [ data[:controller], "resource-form" ].compact.join(" ")
      data[:resource_form_dependencies_value] = dependencies.to_json
      data[:resource_form_loading_value] = false

      options[:class] = [ "form-grid-wrapper", "rf-wrapper", options[:class] ].compact.join(" ")
      options[:data] = data
      options
    end

    def sanitize_resource_field_defs(fields)
      fields.map do |field|
        field = field.symbolize_keys
        validate_resource_field_name!(field[:field])

        sanitized = field.slice(*RESOURCE_ALLOWED_FIELD_KEYS)
        sanitized[:type] = normalize_resource_field_type(sanitized[:type])

        rejected = field.keys - RESOURCE_ALLOWED_FIELD_KEYS
        if rejected.any?
          Rails.logger.warn(
            "[resource_form_helper] unsupported field keys removed: #{rejected.join(', ')} " \
            "(field: #{field[:field]})"
          )
        end

        sanitized
      end
    end

    def validate_resource_field_name!(name)
      unless name.present? && name.to_s.match?(RESOURCE_VALID_FIELD_NAME)
        raise ArgumentError, "Invalid field name: #{name.inspect}"
      end
    end

    def normalize_resource_field_type(type)
      normalized = type.to_s.tr("-", "_")
      unless RESOURCE_FIELD_TYPES.include?(normalized)
        raise ArgumentError, "Unsupported field type: #{type.inspect}"
      end
      normalized
    end

    def extract_dependencies(fields)
      deps = {}
      fields.each do |field|
        next unless field[:depends_on].present?

        deps[field[:field].to_s] = {
          parent: field[:depends_on].to_s,
          filter_key: (field[:depends_filter] || field[:depends_on]).to_s
        }
      end
      deps
    end
end
