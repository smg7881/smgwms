class StdCountry < ApplicationRecord
  self.table_name = "std_countries"

  validates :ctry_cd, presence: true, uniqueness: true, length: { maximum: 10 }
  validates :ctry_nm, presence: true, length: { maximum: 120 }
  validates :ctry_eng_nm, presence: true, length: { maximum: 120 }
  validates :ctry_ar_cd, presence: true, length: { maximum: 30 }
  validates :ctry_telno, length: { maximum: 20 }, allow_blank: true
  validates :use_yn_cd, inclusion: { in: %w[Y N] }

  before_validation :normalize_fields
  before_save :assign_audit_fields
  before_create :assign_create_fields

  scope :ordered, -> { order(:ctry_cd) }
  scope :active, -> { where(use_yn_cd: "Y") }

  private
    def normalize_fields
      self.ctry_cd = ctry_cd.to_s.strip.upcase
      self.ctry_nm = ctry_nm.to_s.strip
      self.ctry_eng_nm = ctry_eng_nm.to_s.strip
      self.ctry_ar_cd = ctry_ar_cd.to_s.strip.upcase
      self.ctry_telno = ctry_telno.to_s.strip.presence
      self.corp_cd = corp_cd.to_s.strip.upcase.presence
      self.corp_nm = corp_nm.to_s.strip.presence
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
