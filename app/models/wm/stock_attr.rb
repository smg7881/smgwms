class Wm::StockAttr < ApplicationRecord
  self.table_name = "tb_wm04001"
  self.primary_key = "stock_attr_no"

  validates :stock_attr_no, presence: true, uniqueness: true
  validates :corp_cd, presence: true
  validates :cust_cd, presence: true
  validates :item_cd, presence: true

  before_save :assign_update_audit_fields
  before_create :assign_create_audit_fields

  STOCK_ATTR_COLS = Wm::GrPrarDtl::STOCK_ATTR_COLS

  def self.find_or_create_for(corp_cd:, cust_cd:, item_cd:, attrs:, actor: "system")
    conds = { corp_cd: corp_cd, cust_cd: cust_cd, item_cd: item_cd }
    STOCK_ATTR_COLS.each { |col| conds[col] = attrs[col].to_s.strip.presence }

    existing = where(conds).first
    return existing if existing

    new_no = generate_no
    create!(conds.merge(stock_attr_no: new_no))
  end

  def self.generate_no
    "SA" + Time.current.strftime("%y%m%d%H%M%S") + format("%03d", rand(999))
  end

  private
    def assign_update_audit_fields
      self.update_by   = Current.user&.user_id_code || "system"
      self.update_time = Time.current
    end

    def assign_create_audit_fields
      self.create_by   = Current.user&.user_id_code || "system"
      self.create_time = Time.current
    end
end
