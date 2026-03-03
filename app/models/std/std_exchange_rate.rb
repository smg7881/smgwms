class StdExchangeRate < ApplicationRecord
  include Std::Auditable

  self.table_name = "std_exchange_rates"

  validates :ctry_cd, presence: true, length: { maximum: 10 }
  validates :fnc_or_cd, presence: true, length: { maximum: 20 }
  validates :std_ymd, presence: true
  validates :anno_dgrcnt, presence: true, length: { maximum: 20 }
  validates :mon_cd, presence: true, length: { maximum: 20 }
  validates :if_yn_cd, inclusion: { in: %w[Y N] }
  validates :use_yn_cd, inclusion: { in: %w[Y N] }
  validates :mon_cd, uniqueness: { scope: %i[ctry_cd fnc_or_cd std_ymd anno_dgrcnt] }

  before_validation :normalize_fields

  scope :ordered, -> { order(std_ymd: :desc, ctry_cd: :asc, fnc_or_cd: :asc, anno_dgrcnt: :asc, mon_cd: :asc) }

  private
    def normalize_fields
      self.ctry_cd = ctry_cd.to_s.strip.upcase
      self.fnc_or_cd = fnc_or_cd.to_s.strip.upcase
      self.anno_dgrcnt = anno_dgrcnt.to_s.strip.upcase
      self.mon_cd = mon_cd.to_s.strip.upcase
      self.if_yn_cd = normalize_yn(if_yn_cd, default_value: "N")
      self.use_yn_cd = normalize_yn(use_yn_cd, default_value: "Y")
    end

    def normalize_yn(value, default_value:)
      normalized = value.to_s.strip.upcase
      if normalized.present?
        normalized
      else
        default_value
      end
    end
end
