class Wm::GrPrar < ApplicationRecord
  self.table_name = "tb_wm02001"
  self.primary_key = "gr_prar_no"

  has_many :details, class_name: "Wm::GrPrarDtl",
           foreign_key: "gr_prar_no", dependent: :destroy
  has_many :exec_results, class_name: "Wm::ExceRslt",
           foreign_key: "op_rslt_mngt_no", dependent: :destroy

  validates :gr_prar_no, presence: true, uniqueness: true
  validates :workpl_cd, presence: true
  validates :corp_cd, presence: true
  validates :cust_cd, presence: true
  validates :gr_stat_cd, presence: true

  before_validation :normalize_fields
  before_save :assign_update_audit_fields
  before_create :assign_create_audit_fields

  scope :ordered, -> { order(gr_prar_no: :desc) }

  # 입고상태 코드값 (공통코드 153)
  GR_STAT_PENDING   = "10"  # 미입고
  GR_STAT_PROCESSED = "20"  # 입고처리
  GR_STAT_CONFIRMED = "30"  # 입고확정
  GR_STAT_CANCELLED = "40"  # 입고취소

  def confirmed?
    gr_stat_cd == GR_STAT_CONFIRMED
  end

  def processed?
    gr_stat_cd == GR_STAT_PROCESSED
  end

  private
    def normalize_fields
      self.gr_prar_no = gr_prar_no.to_s.strip.presence
      self.workpl_cd  = workpl_cd.to_s.strip.presence
      self.corp_cd    = corp_cd.to_s.strip.presence
      self.cust_cd    = cust_cd.to_s.strip.presence
      self.gr_stat_cd = gr_stat_cd.to_s.strip.presence || GR_STAT_PENDING
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
