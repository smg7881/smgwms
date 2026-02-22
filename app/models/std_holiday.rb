class StdHoliday < ApplicationRecord
  self.table_name = "std_holidays"

  validates :ctry_cd, presence: true, length: { maximum: 10 }
  validates :ymd, presence: true
  validates :holiday_nm_cd, presence: true, length: { maximum: 120 }
  validates :ymd, uniqueness: { scope: :ctry_cd }
  validates :sat_yn_cd, inclusion: { in: %w[Y N] }
  validates :sunday_yn_cd, inclusion: { in: %w[Y N] }
  validates :clsdy_yn_cd, inclusion: { in: %w[Y N] }
  validates :asmt_holday_yn_cd, inclusion: { in: %w[Y N] }
  validates :event_day_yn_cd, inclusion: { in: %w[Y N] }
  validates :use_yn_cd, inclusion: { in: %w[Y N] }

  before_validation :normalize_fields
  before_save :assign_audit_fields
  before_create :assign_create_fields

  scope :ordered, -> { order(:ctry_cd, :ymd) }

  private
    def normalize_fields
      self.ctry_cd = ctry_cd.to_s.strip.upcase
      self.holiday_nm_cd = holiday_nm_cd.to_s.strip
      self.sat_yn_cd = normalize_yn(sat_yn_cd, default_value: "N")
      self.sunday_yn_cd = normalize_yn(sunday_yn_cd, default_value: "N")
      self.clsdy_yn_cd = normalize_yn(clsdy_yn_cd, default_value: "N")
      self.asmt_holday_yn_cd = normalize_yn(asmt_holday_yn_cd, default_value: "N")
      self.event_day_yn_cd = normalize_yn(event_day_yn_cd, default_value: "N")
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
