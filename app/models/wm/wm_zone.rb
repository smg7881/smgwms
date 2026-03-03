class WmZone < ApplicationRecord
  self.table_name = "wm_zones"

  validates :workpl_cd, presence: true, length: { maximum: 50 }
  validates :area_cd, presence: true, length: { maximum: 50 }
  validates :zone_cd, presence: true, length: { maximum: 50 }, uniqueness: { scope: [ :workpl_cd, :area_cd ] }
  validates :zone_nm, presence: true, length: { maximum: 100 }
  validates :zone_desc, length: { maximum: 500 }, allow_blank: true
  validates :use_yn, inclusion: { in: %w[Y N] }
  validate :area_exists

  before_validation :normalize_fields
  before_save :assign_audit_fields
  before_create :assign_create_fields

  scope :ordered, -> { order(:workpl_cd, :area_cd, :zone_cd) }

  private
    def normalize_fields
      self.workpl_cd = workpl_cd.to_s.strip.upcase
      self.area_cd = area_cd.to_s.strip.upcase
      self.zone_cd = zone_cd.to_s.strip.upcase
      self.zone_nm = zone_nm.to_s.strip
      self.zone_desc = zone_desc.to_s.strip.presence
      self.use_yn = use_yn.to_s.strip.upcase.presence || "Y"
    end

    def area_exists
      return if workpl_cd.blank? || area_cd.blank?
      return if WmArea.exists?(workpl_cd: workpl_cd, area_cd: area_cd)

      errors.add(:area_cd, "does not exist")
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
