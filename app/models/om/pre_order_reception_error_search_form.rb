class Om::PreOrderReceptionErrorSearchForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :cust_cd, :string
  attribute :cust_nm, :string
  attribute :cust_ord_no, :string
  attribute :resolved_yn, :string, default: "N"
  attribute :recp_start_ymd, :string, default: -> { Date.current.strftime("%Y-%m-%d") }
  attribute :recp_end_ymd, :string, default: -> { Date.current.strftime("%Y-%m-%d") }

  def persisted?
    false
  end

  def self.model_name
    ActiveModel::Name.new(self, nil, "q")
  end
end
