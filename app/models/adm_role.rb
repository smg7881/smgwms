class AdmRole < ApplicationRecord
  self.table_name = "adm_roles"

  validates :role_cd, presence: true, uniqueness: true, length: { maximum: 50 }
  validates :role_nm, presence: true, length: { maximum: 100 }
  validates :use_yn, inclusion: { in: %w[Y N] }

  before_validation :normalize_fields
  before_save :assign_update_audit_fields
  before_create :assign_create_audit_fields

  scope :ordered, -> { order(:role_cd) }

  private
    def normalize_fields
      self.role_cd = role_cd.to_s.strip.upcase
      self.role_nm = role_nm.to_s.strip
      self.description = description.to_s.strip.presence
      self.use_yn = use_yn.to_s.strip.upcase.presence || "Y"
    end

    def assign_update_audit_fields
      actor = current_actor
      self.update_by = actor
      self.update_time = Time.current
    end

    def assign_create_audit_fields
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
