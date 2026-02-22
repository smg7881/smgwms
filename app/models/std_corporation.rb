class StdCorporation < ApplicationRecord
  include Std::Auditable

  self.table_name = "std_corporations"

  has_many :country_rows,
           class_name: "StdCorporationCountry",
           foreign_key: :corp_cd,
           primary_key: :corp_cd,
           inverse_of: :corporation,
           dependent: :delete_all

  validates :corp_cd, presence: true, uniqueness: true, length: { maximum: 20 }
  validates :corp_nm, presence: true, length: { maximum: 120 }
  validates :indstype_cd, presence: true, length: { maximum: 120 }
  validates :bizcond_cd, presence: true, length: { maximum: 120 }
  validates :rptr_nm_cd, presence: true, length: { maximum: 120 }
  validates :use_yn_cd, inclusion: { in: %w[Y N] }

  before_validation :assign_corp_cd, on: :create
  before_validation :normalize_fields

  scope :ordered, -> { order(:corp_cd) }

  private
    def assign_corp_cd
      if corp_cd.to_s.strip.present?
        return
      end

      numeric_codes = self.class.pluck(:corp_cd).filter_map do |code|
        stripped = code.to_s.strip
        if stripped.match?(/\A\d+\z/)
          stripped.to_i
        end
      end
      self.corp_cd = format("%08d", numeric_codes.max.to_i + 1)
    end

    def normalize_fields
      self.corp_cd = corp_cd.to_s.strip.upcase
      self.corp_nm = corp_nm.to_s.strip
      self.indstype_cd = indstype_cd.to_s.strip
      self.bizcond_cd = bizcond_cd.to_s.strip
      self.rptr_nm_cd = rptr_nm_cd.to_s.strip
      self.compreg_slip_cd = compreg_slip_cd.to_s.strip.presence
      self.upper_corp_cd = upper_corp_cd.to_s.strip.upcase.presence
      self.zip_cd = zip_cd.to_s.strip.presence
      self.addr_cd = addr_cd.to_s.strip.presence
      self.dtl_addr_cd = dtl_addr_cd.to_s.strip.presence
      self.vat_sctn_cd = vat_sctn_cd.to_s.strip.upcase.presence
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
