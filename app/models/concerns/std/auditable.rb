module Std::Auditable
  extend ActiveSupport::Concern

  included do
    before_save :assign_std_update_audit_fields
    before_create :assign_std_create_audit_fields
  end

  private
    def assign_std_update_audit_fields
      actor = std_current_actor
      self.update_by = actor
      self.update_time = Time.current
    end

    def assign_std_create_audit_fields
      actor = std_current_actor
      self.create_by = actor
      self.create_time = Time.current
    end

    def std_current_actor
      if Current.user&.user_id_code.present?
        Current.user.user_id_code
      elsif Current.user&.email_address.present?
        Current.user.email_address
      else
        "system"
      end
    end
end
