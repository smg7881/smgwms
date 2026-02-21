class Std::BasePageComponent < ApplicationComponent
  def initialize(query_params:)
    @query_params = query_params
  end

  private
    attr_reader :query_params

    def create_url = collection_path
    def update_url = member_path(":id")
    def delete_url = member_path(":id")
    def grid_url = collection_path(format: :json, q: query_params["q"])

    def common_code_options(code, include_all: false, all_label: "ALL", value_transform: nil)
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

    def collection_path(**) = raise(NotImplementedError, "Subclasses must implement collection_path")
    def member_path(id, **) = raise(NotImplementedError, "Subclasses must implement member_path")
end
