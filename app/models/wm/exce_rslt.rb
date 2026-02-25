class Wm::ExceRslt < ApplicationRecord
  self.table_name = "tb_wm05001"
  self.primary_key = "exce_rslt_no"

  belongs_to :gr_prar, class_name: "Wm::GrPrar",
             foreign_key: "op_rslt_mngt_no", optional: true

  validates :exce_rslt_no, presence: true, uniqueness: true
  validates :exce_rslt_type, inclusion: { in: %w[DP CC] }

  before_save :assign_update_audit_fields
  before_create :assign_create_audit_fields

  EXCE_RSLT_TYPE_DP = "DP"  # 입고
  EXCE_RSLT_TYPE_CC = "CC"  # 취소

  def self.generate_no
    "ER" + Time.current.strftime("%y%m%d%H%M%S") + format("%03d", rand(999))
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
