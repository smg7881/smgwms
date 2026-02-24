class Om::CustomerSystemConfigSearchForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :setup_unit_cd, :string, default: "SYSTEM"
  attribute :cust_cd, :string
  attribute :cust_nm, :string
  attribute :lclas_cd, :string
  attribute :mclas_cd, :string
  attribute :sclas_cd, :string
  attribute :setup_sctn_cd, :string
  attribute :module_nm, :string
  attribute :use_yn, :string, default: "Y"

  def persisted?
    false
  end

  def self.model_name
    ActiveModel::Name.new(self, nil, "q")
  end
end
