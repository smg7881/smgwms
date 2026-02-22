class StdRegion < ApplicationRecord
  self.table_name = "std_regions"

  validates :corp_cd, presence: true, length: { maximum: 20 }
  validates :regn_cd, presence: true, uniqueness: true, length: { maximum: 10 }
  validates :regn_nm_cd, presence: true, length: { maximum: 120 }
  validates :regn_eng_nm_cd, presence: true, length: { maximum: 120 }
  validates :use_yn_cd, inclusion: { in: %w[Y N] }

  before_validation :assign_regn_cd, on: :create
  before_validation :normalize_fields
  before_save :assign_audit_fields
  before_create :assign_create_fields

  scope :ordered, -> { order(:corp_cd, :regn_cd) }

  private
    def assign_regn_cd
      if regn_cd.to_s.strip.present?
        return
      end

      numeric_codes = self.class.pluck(:regn_cd).filter_map do |code|
        stripped = code.to_s.strip
        if stripped.match?(/\A\d+\z/)
          stripped.to_i
        end
      end
      next_number = numeric_codes.max.to_i + 1
      self.regn_cd = format("%010d", next_number)
    end

    def normalize_fields
      self.corp_cd = corp_cd.to_s.strip.upcase
      self.regn_cd = regn_cd.to_s.strip.upcase
      self.regn_nm_cd = regn_nm_cd.to_s.strip
      self.regn_eng_nm_cd = regn_eng_nm_cd.to_s.strip
      self.upper_regn_cd = upper_regn_cd.to_s.strip.upcase.presence
      self.rmk_cd = rmk_cd.to_s.strip.presence
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

    def assign_audit_fields
      actor = current_actor
      self.update_by = actor
      self.update_time = Time.current
    end

    def assign_create_fields
      actor = current_actor
      self.create_by = actor
      self.create_time = Time.current
    end

    def current_actor
      if Current.user&.user_id_code.present?
        Current.user.user_id_code
      elsif Current.user&.email_address.present?
        Current.user.email_address
      else
        "system"
      end
    end
end
