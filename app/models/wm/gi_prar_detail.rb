class Wm::GiPrarDetail < ApplicationRecord
  self.table_name = "wm_gi_prar_details"

  STOCK_ATTR_COLS = (1..10).map { |index| "stock_attr_col#{index.to_s.rjust(2, '0')}" }.freeze

  belongs_to :gi_prar, class_name: "Wm::GiPrar", foreign_key: "gi_prar_no"

  validates :gi_prar_no, presence: true
  validates :lineno, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :item_cd, presence: true
  validates :gi_idct_qty, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :gi_rslt_qty, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :assign_qty, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :pick_qty, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  before_validation :normalize_fields
  before_save :assign_update_audit_fields
  before_create :assign_create_audit_fields

  scope :ordered, -> { order(:lineno) }

  private
    def normalize_fields
      self.item_cd = item_cd.to_s.strip.upcase.presence
      self.item_nm = item_nm.to_s.strip.presence
      self.unit_cd = unit_cd.to_s.strip.upcase.presence
      self.gi_idct_qty = gi_idct_qty.to_f
      self.gi_rslt_qty = gi_rslt_qty.to_f
      self.assign_qty = assign_qty.to_f
      self.pick_qty = pick_qty.to_f
      self.gi_stat_cd = gi_stat_cd.to_s.strip.upcase.presence || Wm::GiPrar::GI_STAT_INSTRUCTED
      self.rmk = rmk.to_s.strip.presence

      STOCK_ATTR_COLS.each do |column_name|
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
