class SearchPopupForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :display, :string
  attribute :code, :string

  def persisted?
    false
  end
end
