class Wm::GiPick < ApplicationRecord
  self.table_name = "wm_gi_picks"
  self.primary_key = "pick_no"

  PICK_STAT_INSTRUCTED = "10"
  PICK_STAT_ASSIGNED = "20"
  PICK_STAT_PICKED = "30"
  PICK_STAT_CONFIRMED = "40"

  belongs_to :gi_prar, class_name: "Wm::GiPrar", foreign_key: "gi_prar_no"

  validates :pick_no, presence: true, uniqueness: true
  validates :gi_prar_no, presence: true
  validates :lineno, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :item_cd, presence: true
  validates :stock_qty, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :assign_qty, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :pick_qty, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  before_validation :normalize_fields
  before_save :assign_update_audit_fields
  before_create :assign_create_audit_fields

  scope :ordered, -> { order(:lineno, :pick_no) }

  def self.generate_no
    "GP" + Time.current.strftime("%y%m%d%H%M%S") + format("%03d", rand(1000))
  end

  private
    def normalize_fields
      self.pick_no = pick_no.to_s.strip.upcase.presence
      self.gi_prar_no = gi_prar_no.to_s.strip.presence
      self.item_cd = item_cd.to_s.strip.upcase.presence
      self.item_nm = item_nm.to_s.strip.presence
      self.unit_cd = unit_cd.to_s.strip.upcase.presence
      self.loc_cd = loc_cd.to_s.strip.upcase.presence
      self.stock_attr_no = stock_attr_no.to_s.strip.upcase.presence
      self.stock_qty = stock_qty.to_f
      self.assign_qty = assign_qty.to_f
      self.pick_qty = pick_qty.to_f
      self.pick_stat_cd = pick_stat_cd.to_s.strip.upcase.presence || PICK_STAT_INSTRUCTED
      self.rmk = rmk.to_s.strip.presence

      Wm::GiPrarDetail::STOCK_ATTR_COLS.each do |column_name|
        raw_value = public_send(column_name).to_s.strip
        public_send("#{column_name}=", raw_value.presence)
      end
    end

    def assign_update_audit_fields
      self.update_by = current_actor
      self.update_time = Time.current
    end

    def assign_create_audit_fields
      self.create_by = current_actor
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
