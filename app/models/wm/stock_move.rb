class Wm::StockMove < ApplicationRecord
  self.table_name = "wm_stock_moves"

  STOCK_ATTR_COLUMNS = (1..10).map { |index| "stock_attr_col#{index.to_s.rjust(2, '0')}" }.freeze

  validates :corp_cd, :workpl_cd, :cust_cd, :item_cd, :stock_attr_no, :from_loc_cd, :to_loc_cd, presence: true
  validates :move_qty, numericality: { greater_than: 0 }
  validates :move_type, inclusion: { in: %w[MV] }
  validates :move_ymd, length: { is: 8 }
  validates :move_hms, length: { is: 6 }

  before_validation :normalize_fields
  before_save :assign_update_audit_fields
  before_create :assign_create_audit_fields

  scope :ordered, -> { order(move_ymd: :desc, move_hms: :desc, id: :desc) }

  private
    def normalize_fields
      self.corp_cd = corp_cd.to_s.strip.upcase
      self.workpl_cd = workpl_cd.to_s.strip.upcase
      self.cust_cd = cust_cd.to_s.strip.upcase
      self.item_cd = item_cd.to_s.strip.upcase
      self.stock_attr_no = stock_attr_no.to_s.strip.upcase
      self.from_loc_cd = from_loc_cd.to_s.strip.upcase
      self.to_loc_cd = to_loc_cd.to_s.strip.upcase
      self.basis_unit_cls = basis_unit_cls.to_s.strip.upcase.presence
      self.basis_unit_cd = basis_unit_cd.to_s.strip.upcase.presence
      self.move_type = move_type.to_s.strip.upcase.presence || "MV"

      STOCK_ATTR_COLUMNS.each do |column_name|
        value = public_send(column_name).to_s.strip
        public_send("#{column_name}=", value.presence)
      end

      if move_ymd.to_s.strip.blank?
        self.move_ymd = Time.current.strftime("%Y%m%d")
      end
      if move_hms.to_s.strip.blank?
        self.move_hms = Time.current.strftime("%H%M%S")
      end
    end

    def assign_update_audit_fields
      self.update_by = Current.user&.user_id_code || "system"
      self.update_time = Time.current
    end

    def assign_create_audit_fields
      self.create_by = Current.user&.user_id_code || "system"
      self.create_time = Time.current
    end
end
