class AdmUserMenuPermission < ApplicationRecord
  belongs_to :user, class_name: "User"

  validates :menu_cd, presence: true, length: { maximum: 20 }, uniqueness: { scope: :user_id }
  validates :use_yn, inclusion: { in: %w[Y N] }

  before_validation :normalize_fields
  before_save :assign_audit_fields
  before_create :assign_create_fields

  scope :active, -> { where(use_yn: "Y") }

  class << self
    def allowed_menu_codes_for(user)
      return [] if user.blank?

      active.where(user_id: user.id).pluck(:menu_cd)
    end
  end

  private
    def normalize_fields
      self.menu_cd = menu_cd.to_s.strip.upcase
      self.use_yn = use_yn.to_s.strip.upcase.presence || "Y"
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
