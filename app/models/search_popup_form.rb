class SearchPopupForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :display, :string
  attribute :code, :string

  # Corp popup fields (PRD: 법인코드 / 법인명 / 사용여부)
  attribute :corp_cd, :string
  attribute :corp_nm, :string
  attribute :use_yn, :string, default: "Y"
  attribute :ctry_cd, :string
  attribute :fnc_or_cd, :string
  attribute :fnc_or_nm, :string
  attribute :sellbuy_attr_cd, :string
  attribute :sellbuy_attr_nm, :string
  attribute :tran_yn, :string
  attribute :strg_yn, :string

  def persisted?
    false
  end
end
