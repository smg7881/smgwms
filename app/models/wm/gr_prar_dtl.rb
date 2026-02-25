class Wm::GrPrarDtl < ApplicationRecord
  self.table_name = "tb_wm02002"

  belongs_to :gr_prar, class_name: "Wm::GrPrar", foreign_key: "gr_prar_no"

  validates :gr_prar_no, presence: true
  validates :lineno, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :item_cd, presence: true
  validates :gr_qty, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  before_validation :normalize_fields
  before_save :assign_update_audit_fields
  before_create :assign_create_audit_fields

  STOCK_ATTR_COLS = (1..10).map { |i| "stock_attr_col#{i.to_s.rjust(2, '0')}" }.freeze

  def available_stock_attrs
    STOCK_ATTR_COLS.each_with_object({}) do |col, h|
      h[col] = send(col)
    end
  end

  private
    def normalize_fields
      self.gr_qty      = gr_qty.to_f
      self.gr_rslt_qty = gr_rslt_qty.to_f
      self.gr_stat_cd  = gr_stat_cd.presence || Wm::GrPrar::GR_STAT_PENDING
    end

    def assign_update_audit_fields
      self.update_by   = current_actor
      self.update_time = Time.current
    end

    def assign_create_audit_fields
      self.create_by   = current_actor
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
