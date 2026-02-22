class StdZipCode < ApplicationRecord
  self.table_name = "std_zip_codes"

  validates :ctry_cd, presence: true, length: { maximum: 10 }
  validates :zipcd, presence: true, length: { maximum: 20 }
  validates :seq_no, presence: true, numericality: { only_integer: true }
  validates :seq_no, uniqueness: { scope: [ :ctry_cd, :zipcd ] }
  validates :use_yn_cd, inclusion: { in: %w[Y N] }

  before_validation :normalize_fields
  before_save :assign_audit_fields
  before_create :assign_create_fields

  scope :ordered, -> { order(:ctry_cd, :zipcd, :seq_no) }
  scope :active, -> { where(use_yn_cd: "Y") }

  private
    def normalize_fields
      self.ctry_cd = ctry_cd.to_s.strip.upcase
      self.zipcd = zipcd.to_s.strip.upcase
      self.seq_no = seq_no.to_i
      self.zipaddr = zipaddr.to_s.strip.presence
      self.sido = sido.to_s.strip.presence
      self.sgng = sgng.to_s.strip.presence
      self.eupdiv = eupdiv.to_s.strip.presence
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
