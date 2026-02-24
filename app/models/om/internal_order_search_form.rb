class Om::InternalOrderSearchForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :ord_no, :string

  def persisted?
    false
  end

  def self.model_name
    ActiveModel::Name.new(self, nil, "q")
  end
end
