class Ui::ResourceFormComponent < ApplicationComponent
  ALLOWED_FIELD_KEYS = %i[
    field type label label_key placeholder placeholder_key
    span options required disabled readonly value target
    rowspan colspan row_span col_span
    pattern minlength maxlength inputmode autocomplete
    date_type min max step
    rows cols
    include_blank help
    depends_on depends_filter
    input_type
  ].freeze

  VALID_FIELD_NAME = /\A[a-zA-Z0-9_]+\z/
  FIELD_TYPES = %w[input number select date_picker textarea rich_textarea checkbox radio switch photo].freeze

  def initialize(model:, fields:, url: nil, cols: 3,
                 show_buttons: true, submit_label: "저장",
                 cancel_url: nil, form_data: {}, form_html: {},
                 target_controller: nil, **html_options)
    @model = model
    @fields = fields
    @url = url
    @cols = cols
    @show_buttons = show_buttons
    @submit_label = submit_label
    @cancel_url = cancel_url
    @form_data = form_data
    @form_html = form_html
    @target_controller = target_controller
    @html_options = html_options
  end

  private
    attr_reader :model, :fields, :url, :cols, :show_buttons,
                :submit_label, :cancel_url, :form_data, :form_html,
                :target_controller, :html_options

    def safe_fields
      @safe_fields ||= sanitize_resource_field_defs(fields)
    end

    def dependencies
      @dependencies ||= extract_dependencies(safe_fields)
    end

    def wrapper_attrs
      opts = html_options.deep_dup
      data = (opts.delete(:data) || {}).deep_dup

      data[:controller] = [ data[:controller], "resource-form" ].compact.join(" ")
      data[:resource_form_dependencies_value] = dependencies.to_json
      data[:resource_form_loading_value] = false

      opts[:class] = [ "max-w-full overflow-x-hidden bg-bg-secondary border border-border rounded-lg p-5 mb-4", opts[:class] ].compact.join(" ")
      opts[:data] = data
      opts
    end

    def merged_form_data
      {
        resource_form_target: "form",
        action: "submit->resource-form#submit"
      }.merge(form_data)
    end

    def merged_form_html
      { novalidate: true }.merge(form_html)
    end

    def sanitize_resource_field_defs(fields)
      fields.map do |field|
        field = field.symbolize_keys
        validate_resource_field_name!(field[:field])

        sanitized = field.slice(*ALLOWED_FIELD_KEYS)
        sanitized[:type] = normalize_resource_field_type(sanitized[:type])

        rejected = field.keys - ALLOWED_FIELD_KEYS
        if rejected.any?
          Rails.logger.warn(
            "[ResourceFormComponent] unsupported field keys removed: #{rejected.join(', ')} " \
            "(field: #{field[:field]})"
          )
        end

        sanitized
      end
    end

    def validate_resource_field_name!(name)
      unless name.present? && name.to_s.match?(VALID_FIELD_NAME)
        raise ArgumentError, "Invalid field name: #{name.inspect}"
      end
    end

    def normalize_resource_field_type(type)
      normalized = type.to_s.tr("-", "_")
      unless FIELD_TYPES.include?(normalized)
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
