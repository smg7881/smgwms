class Ui::SearchFormComponent < ApplicationComponent
  ALLOWED_FIELD_KEYS = %i[
    field type label label_key placeholder placeholder_key
    span options required clearable disabled
    pattern minlength maxlength inputmode autocomplete
    date_type date_format min max
    popup_type code_field
    include_blank help
  ].freeze

  VALID_FIELD_NAME = /\A[a-zA-Z0-9_]+\z/
  FIELD_TYPES = %w[input select date_picker date_range popup].freeze

  def initialize(fields:, url:, turbo_frame: "main-content",
                 cols: 3, enable_collapse: true, collapsed_rows: 1,
                 show_buttons: true, **html_options)
    @fields = fields
    @url = url
    @turbo_frame = turbo_frame
    @cols = cols
    @enable_collapse = enable_collapse
    @collapsed_rows = collapsed_rows
    @show_buttons = show_buttons
    @html_options = html_options
  end

  private
    attr_reader :fields, :url, :turbo_frame, :cols,
                :enable_collapse, :collapsed_rows, :show_buttons, :html_options

    def safe_fields
      @safe_fields ||= sanitize_field_defs(fields)
    end

    def wrapper_attrs
      opts = html_options.dup
      custom_data = opts.delete(:data) || {}

      stimulus_data = {
        controller: "search-form",
        "search-form-collapsed-value" => enable_collapse,
        "search-form-enable-collapse-value" => enable_collapse,
        "search-form-collapsed-rows-value" => collapsed_rows,
        "search-form-cols-value" => cols
      }

      opts.merge(class: "max-w-full overflow-x-hidden bg-bg-secondary border border-border rounded-lg p-4 mb-4", data: custom_data.merge(stimulus_data))
    end

    def sanitize_field_defs(fields)
      fields.map do |field|
        field = field.symbolize_keys
        validate_field_name!(field[:field])

        sanitized = field.slice(*ALLOWED_FIELD_KEYS)
        sanitized[:type] = normalize_field_type(sanitized[:type])

        if sanitized[:type] == "popup"
          if sanitized[:code_field].blank?
            raise ArgumentError, "popup 필드에는 code_field가 필요합니다 (field: #{field[:field]})"
          end
          validate_field_name!(sanitized[:code_field])
        end

        rejected = field.keys - ALLOWED_FIELD_KEYS
        if rejected.any?
          Rails.logger.warn(
            "[SearchFormComponent] 허용되지 않은 필드 키 제거: #{rejected.join(', ')} " \
            "(field: #{field[:field]})"
          )
        end

        sanitized
      end
    end

    def validate_field_name!(name)
      unless name.present? && name.to_s.match?(VALID_FIELD_NAME)
        raise ArgumentError, "유효하지 않은 필드 이름: #{name.inspect}"
      end
    end

    def normalize_field_type(type)
      normalized = type.to_s.tr("-", "_")
      unless FIELD_TYPES.include?(normalized)
        raise ArgumentError, "지원하지 않는 필드 타입: #{type.inspect}"
      end
      normalized
    end
end
