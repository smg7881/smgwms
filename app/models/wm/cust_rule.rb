class Wm::CustRule < ApplicationRecord
  self.table_name = "wm_cust_rules"

  validates :workpl_cd, presence: true, length: { maximum: 50 }
  validates :cust_cd, presence: true, length: { maximum: 50 }
  validates :inout_sctn, presence: true, length: { maximum: 50 }
  validates :inout_type, presence: true, length: { maximum: 50 }
  validates :rule_sctn, presence: true, length: { maximum: 50 }
  validates :aply_yn, inclusion: { in: %w[Y N] }

  before_validation :normalize_fields
  before_save :assign_update_audit_fields
  before_create :assign_create_audit_fields

  scope :ordered, -> { order(:id) }

  private
    def normalize_fields
      self.workpl_cd = workpl_cd.to_s.strip.upcase
      self.cust_cd = cust_cd.to_s.strip.upcase
      self.inout_sctn = inout_sctn.to_s.strip
      self.inout_type = inout_type.to_s.strip
      self.rule_sctn = rule_sctn.to_s.strip
      self.aply_yn = aply_yn.to_s.strip.upcase.presence || "Y"
      self.remark = remark.to_s.strip.presence
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
