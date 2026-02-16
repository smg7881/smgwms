class System::BasePageComponent < ApplicationComponent
  def initialize(query_params:)
    @query_params = query_params
  end

  private
    attr_reader :query_params

    def create_url = collection_path
    def update_url = member_path(":id")
    def delete_url = member_path(":id")
    def grid_url   = collection_path(format: :json, q: query_params["q"])

    # Subclasses must implement
    def collection_path(**) = raise(NotImplementedError)
    def member_path(id, **) = raise(NotImplementedError)
end
