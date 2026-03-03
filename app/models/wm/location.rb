class WmLocation < ApplicationRecord
  self.table_name = "wm_locations"

  LOCATION_CLASS_CODES = %w[STORAGE PICKING MOVE].freeze
  LOCATION_TYPE_CODES = %w[NORMAL RACK FLOOR].freeze

  validates :workpl_cd, presence: true, length: { maximum: 50 }
  validates :area_cd, presence: true, length: { maximum: 50 }
  validates :zone_cd, presence: true, length: { maximum: 50 }
  validates :loc_cd, presence: true, length: { maximum: 50 }, uniqueness: { scope: [ :workpl_cd, :area_cd, :zone_cd ] }
  validates :loc_nm, presence: true, length: { maximum: 100 }
  validates :loc_class_cd, inclusion: { in: LOCATION_CLASS_CODES }, allow_blank: true
  validates :loc_type_cd, inclusion: { in: LOCATION_TYPE_CODES }, allow_blank: true
  validates :width_len, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :vert_len, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :height_len, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :max_weight, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :max_cbm, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :has_stock, inclusion: { in: %w[Y N] }
  validates :use_yn, inclusion: { in: %w[Y N] }
  validate :zone_exists

  before_validation :normalize_fields
  before_save :assign_audit_fields
  before_create :assign_create_fields

  scope :ordered, -> { order(:workpl_cd, :area_cd, :zone_cd, :loc_cd) }

  private
    def normalize_fields
      self.workpl_cd = workpl_cd.to_s.strip.upcase
      self.area_cd = area_cd.to_s.strip.upcase
      self.zone_cd = zone_cd.to_s.strip.upcase
      self.loc_cd = loc_cd.to_s.strip.upcase
      self.loc_nm = loc_nm.to_s.strip
      self.loc_class_cd = loc_class_cd.to_s.strip.upcase.presence
      self.loc_type_cd = loc_type_cd.to_s.strip.upcase.presence
      self.width_len = normalize_numeric(width_len)
      self.vert_len = normalize_numeric(vert_len)
      self.height_len = normalize_numeric(height_len)
      self.max_weight = normalize_numeric(max_weight)
      self.max_cbm = normalize_numeric(max_cbm)
      self.has_stock = has_stock.to_s.strip.upcase.presence || "N"
      self.use_yn = use_yn.to_s.strip.upcase.presence || "Y"
    end

    def normalize_numeric(value)
      if value.is_a?(String)
        stripped = value.strip
        return nil if stripped.blank?

        stripped
      else
        value
      end
    end

    def zone_exists
      return if workpl_cd.blank? || area_cd.blank? || zone_cd.blank?
      return if WmZone.exists?(workpl_cd: workpl_cd, area_cd: area_cd, zone_cd: zone_cd)

      errors.add(:zone_cd, "does not exist")
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
