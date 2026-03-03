class StdFinancialInstitution < ApplicationRecord
  include Std::Auditable

  self.table_name = "std_financial_institutions"

  validates :fnc_or_cd, presence: true, uniqueness: true, length: { maximum: 20 }
  validates :fnc_or_nm, presence: true, length: { maximum: 120 }
  validates :fnc_or_eng_nm, presence: true, length: { maximum: 120 }
  validates :ctry_cd, length: { maximum: 10 }, allow_blank: true
  validates :ctry_nm, length: { maximum: 120 }, allow_blank: true
  validates :use_yn_cd, inclusion: { in: %w[Y N] }

  before_validation :normalize_fields

  scope :ordered, -> { order(:fnc_or_cd) }
  scope :active, -> { where(use_yn_cd: "Y") }

  private
    def normalize_fields
      self.fnc_or_cd = fnc_or_cd.to_s.strip.upcase
      self.fnc_or_nm = fnc_or_nm.to_s.strip
      self.fnc_or_eng_nm = fnc_or_eng_nm.to_s.strip
      self.ctry_cd = ctry_cd.to_s.strip.upcase.presence
      self.ctry_nm = ctry_nm.to_s.strip.presence
      self.use_yn_cd = normalize_yn(use_yn_cd, default_value: "Y")
      resolve_country_name
    end

    def normalize_yn(value, default_value:)
      normalized = value.to_s.strip.upcase
      if normalized.present?
        normalized
      else
        default_value
      end
    end

    def resolve_country_name
      return if ctry_cd.blank?
      return if ctry_nm.present?
      return unless defined?(StdCountry) && StdCountry.table_exists?

      self.ctry_nm = StdCountry.find_by(ctry_cd: ctry_cd)&.ctry_nm
    rescue ActiveRecord::StatementInvalid
      self.ctry_nm = nil
    end
end
