class Om::OrderManualCompletionSearchForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :cust_cd, :string
  attribute :cust_nm, :string
  attribute :date_type, :string, default: "create_time"
  attribute :start_date, :date
  attribute :end_date, :date
  attribute :ord_no, :string

  def persisted?
    false
  end

  def self.model_name
    ActiveModel::Name.new(self, nil, "q")
  end
end
