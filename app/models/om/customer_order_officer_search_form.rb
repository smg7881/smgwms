class Om::CustomerOrderOfficerSearchForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :dept_cd, :string
  attribute :dept_nm, :string
  attribute :cust_cd, :string
  attribute :cust_nm, :string
  attribute :exp_imp_dom_sctn_cd, :string, default: ""
  attribute :cust_ofcr_nm, :string

  def persisted?
    false
  end

  def self.model_name
    ActiveModel::Name.new(self, nil, "q")
  end
end
