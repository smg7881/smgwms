class StdCorporationCountry < ApplicationRecord
  include Std::Auditable

  self.table_name = "std_corporation_countries"

  belongs_to :corporation,
             class_name: "StdCorporation",
             foreign_key: :corp_cd,
             primary_key: :corp_cd,
             inverse_of: :country_rows,
             optional: true

  validates :corp_cd, presence: true, length: { maximum: 20 }
  validates :seq, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :ctry_cd, presence: true, length: { maximum: 10 }
  validates :rpt_yn_cd, inclusion: { in: %w[Y N] }
  validates :use_yn_cd, inclusion: { in: %w[Y N] }
  validates :seq, uniqueness: { scope: :corp_cd }

  before_validation :assign_seq, on: :create
  before_validation :normalize_fields

  scope :ordered, -> { order(:corp_cd, :seq) }

  private
    def assign_seq
      if seq.to_i > 0 || corp_cd.to_s.strip.blank?
        return
      end

      self.seq = self.class.where(corp_cd: corp_cd.to_s.strip.upcase).maximum(:seq).to_i + 1
    end

    def normalize_fields
      self.corp_cd = corp_cd.to_s.strip.upcase
      self.ctry_cd = ctry_cd.to_s.strip.upcase
      self.aply_mon_unit_cd = aply_mon_unit_cd.to_s.strip.upcase.presence
      self.timezone_cd = timezone_cd.to_s.strip.presence
      self.std_time = std_time.to_s.strip.presence
      self.summer_time = summer_time.to_s.strip.presence
      self.sys_lang_slc = sys_lang_slc.to_s.strip.upcase.presence
      self.rpt_yn_cd = normalize_yn(rpt_yn_cd, default_value: "N")
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
