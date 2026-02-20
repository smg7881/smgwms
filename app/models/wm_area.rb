class WmArea < ApplicationRecord
  self.table_name = "wm_areas"

  belongs_to :workplace, class_name: "WmWorkplace", foreign_key: :workpl_cd, primary_key: :workpl_cd, optional: true

  validates :workpl_cd, presence: true, length: { maximum: 50 }
  validates :area_cd, presence: true, length: { maximum: 50 }, uniqueness: { scope: :workpl_cd }
  validates :area_nm, presence: true, length: { maximum: 100 }
  validates :area_desc, length: { maximum: 500 }, allow_blank: true
  validates :use_yn, inclusion: { in: %w[Y N] }
  validate :workplace_exists

  before_validation :normalize_fields
  before_save :assign_audit_fields
  before_create :assign_create_fields

  scope :ordered, -> { order(:workpl_cd, :area_cd) }

  private
    def normalize_fields
      self.workpl_cd = workpl_cd.to_s.strip.upcase
      self.area_cd = area_cd.to_s.strip.upcase
      self.area_nm = area_nm.to_s.strip
      self.area_desc = area_desc.to_s.strip.presence
      self.use_yn = use_yn.to_s.strip.upcase.presence || "Y"
    end

    def workplace_exists
      return if workpl_cd.blank?
      return if WmWorkplace.exists?(workpl_cd: workpl_cd)

      errors.add(:workpl_cd, "does not exist")
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
