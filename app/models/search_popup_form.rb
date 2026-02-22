class SearchPopupForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :display, :string
  attribute :code, :string

  # Corp popup fields (PRD: 법인코드 / 법인명 / 사용여부)
  attribute :corp_cd, :string
  attribute :corp_nm, :string
  attribute :use_yn, :string, default: "Y"

  def persisted?
    false
  end
end
