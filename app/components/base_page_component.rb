class BasePageComponent < ApplicationComponent
  def initialize(query_params:)
    @query_params = query_params
  end

  private
    attr_reader :query_params

    def create_url = collection_path
    def update_url = member_path(":id")
    def delete_url = member_path(":id")

    def grid_url
      q_params = query_params["q"]
      q_params = q_params.to_unsafe_h if q_params.respond_to?(:to_unsafe_h)
      collection_path(format: :json, q: q_params)
    end

    def common_code_options(code, include_all: false, all_label: "전체", value_transform: nil)
      AdmCodeDetail.select_options_for(
        code,
        include_all: include_all,
        all_label: all_label,
        value_transform: value_transform
      )
    end

    def common_code_values(code, value_transform: nil)
      AdmCodeDetail.select_values_for(code, value_transform: value_transform)
    end

    def common_code_map(code, value_transform: nil)
      common_code_options(code, value_transform: value_transform).to_h { |opt| [ opt[:value], opt[:label] ] }
    end

    def record_options(model, code_field:, name_field:, include_all: false, all_label: "전체", label_format: nil)
      records = fetch_records(model)
      options = records.map do |record|
        code = record.public_send(code_field)
        name = record.public_send(name_field)
        {
          label: label_format ? label_format.call(code, name) : "#{code} - #{name}",
          value: code
        }
      end
      include_all ? [ { label: all_label, value: "" } ] + options : options
    end

    def record_values(model, code_field:)
      fetch_records(model).map { |record| record.public_send(code_field) }
    end

    def record_map(model, code_field:, name_field:)
      fetch_records(model).to_h { |record| [ record.public_send(code_field), record.public_send(name_field) ] }
    end

    def fetch_records(model)
      @record_cache ||= {}
      @record_cache[model] ||= model.ordered.to_a
    end

    def collection_path(**) = raise(NotImplementedError, "Subclasses must implement collection_path")
    def member_path(id, **) = raise(NotImplementedError, "Subclasses must implement member_path")
end
