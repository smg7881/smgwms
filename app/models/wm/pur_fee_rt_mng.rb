class Wm::PurFeeRtMng < ApplicationRecord
  self.table_name = "tb_wm06001"
  self.primary_key = "wrhs_exca_fee_rt_no"

  has_many :details, class_name: "Wm::PurFeeRtMngDtl", foreign_key: "wrhs_exca_fee_rt_no", dependent: :destroy

  validates :wrhs_exca_fee_rt_no, presence: true, uniqueness: true
  validates :corp_cd, presence: true
  validates :work_pl_cd, presence: true
  validates :use_yn, inclusion: { in: %w[Y N] }
  validates :auto_yn, inclusion: { in: %w[Y N] }

  before_validation :normalize_fields
  before_save :assign_update_audit_fields
  before_create :assign_create_audit_fields

  scope :ordered, -> { order(wrhs_exca_fee_rt_no: :desc) }

  private
    def normalize_fields
      self.corp_cd = corp_cd.to_s.strip.presence
      self.work_pl_cd = work_pl_cd.to_s.strip.presence
      self.sell_buy_sctn_cd = "20" # 항상 매입으로 고정
      self.use_yn = use_yn.to_s.strip.upcase.presence || "Y"
      self.auto_yn = auto_yn.to_s.strip.upcase.presence || "N"
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
