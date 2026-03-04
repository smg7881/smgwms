class Om::WaitingOrderSearchForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :cust_cd, :string
  attribute :cust_nm, :string
  attribute :date_type, :string, default: "CREATE_TIME"
  attribute :start_date, :date
  attribute :end_date, :date

  def persisted?
    false
  end

  def self.model_name
    ActiveModel::Name.new(self, nil, "q")
  end
end
