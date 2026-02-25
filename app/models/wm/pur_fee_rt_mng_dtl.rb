class Wm::PurFeeRtMngDtl < ApplicationRecord
  self.table_name = "tb_wm06002"
  # standard Auto-increment id PK used (tb_wm06002 is recreated with id column)

  belongs_to :pur_fee_rt_mng, class_name: "Wm::PurFeeRtMng", foreign_key: "wrhs_exca_fee_rt_no"

  validates :wrhs_exca_fee_rt_no, presence: true
  validates :lineno, presence: true
  validates :aply_strt_ymd, presence: true
  validates :aply_end_ymd, presence: true
  validates :dcsn_yn, inclusion: { in: %w[Y N] }

  validate :validate_date_range

  before_validation :normalize_fields
  before_save :assign_update_audit_fields
  before_create :assign_create_audit_fields

  private
    def validate_date_range
      return if aply_strt_ymd.blank? || aply_end_ymd.blank?

      if aply_strt_ymd > aply_end_ymd
        errors.add(:aply_end_ymd, "cannot be earlier than start date")
      end
    end

    def normalize_fields
      self.dcsn_yn = dcsn_yn.to_s.strip.upcase.presence || "N"
      self.aply_uprice = aply_uprice.presence || 0
      self.std_work_qty = std_work_qty.presence || 0
    end

    def assign_update_audit_fields
      actor = current_actor
      self.update_by = actor
      self.update_time = Time.current
    end

    def assign_create_audit_fields
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
