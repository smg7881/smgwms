class StdPurchaseContract < ApplicationRecord
  include Std::Auditable

  self.table_name = "std_purchase_contracts"

  has_many :settlements,
           class_name: "StdPurchaseContractSettlement",
           foreign_key: :purchase_contract_id,
           inverse_of: :purchase_contract,
           dependent: :delete_all
  has_many :change_histories,
           class_name: "StdPurchaseContractChangeHistory",
           foreign_key: :purchase_contract_id,
           inverse_of: :purchase_contract,
           dependent: :delete_all

  validates :bzac_cd, presence: true, length: { maximum: 20 }
  validates :pur_ctrt_no, presence: true, uniqueness: true, length: { maximum: 30 }
  validates :pur_ctrt_nm, presence: true, length: { maximum: 200 }
  validates :bizman_no, presence: true, length: { maximum: 20 }
  validates :ctrt_sctn_cd, presence: true, length: { maximum: 30 }
  validates :ctrt_kind_cd, presence: true, length: { maximum: 30 }
  validates :use_yn_cd, inclusion: { in: %w[Y N] }
  validates :loan_limt_over_yn_cd, inclusion: { in: %w[Y N] }
  validates :dcsn_yn_cd, inclusion: { in: %w[Y N] }

  before_validation :assign_pur_ctrt_no, on: :create
  before_validation :normalize_fields

  scope :ordered, -> { order(:pur_ctrt_no) }

  class << self
    def next_pur_ctrt_no
      numbers = pluck(:pur_ctrt_no).filter_map do |code|
        normalized = code.to_s.strip
        if normalized.match?(/\APC\d+\z/)
          normalized.delete_prefix("PC").to_i
        end
      end

      "PC#{format('%08d', numbers.max.to_i + 1)}"
    end
  end

  private
    def assign_pur_ctrt_no
      if pur_ctrt_no.to_s.strip.present?
        return
      end

      self.pur_ctrt_no = self.class.next_pur_ctrt_no
    end

    def normalize_fields
      self.corp_cd = corp_cd.to_s.strip.upcase.presence
      self.bzac_cd = bzac_cd.to_s.strip.upcase
      self.pur_ctrt_no = pur_ctrt_no.to_s.strip.upcase
      self.pur_ctrt_nm = pur_ctrt_nm.to_s.strip
      self.bizman_no = bizman_no.to_s.gsub(/[^0-9]/, "")
      self.ctrt_sctn_cd = ctrt_sctn_cd.to_s.strip.upcase
      self.ctrt_kind_cd = ctrt_kind_cd.to_s.strip.upcase
      self.bef_ctrt_no = bef_ctrt_no.to_s.strip.upcase.presence
      self.cprtco_ofcr_cd = cprtco_ofcr_cd.to_s.strip.upcase.presence
      self.ctrt_cnctr_reason_cd = ctrt_cnctr_reason_cd.to_s.strip.upcase.presence
      self.ctrt_ofcr_cd = ctrt_ofcr_cd.to_s.strip.upcase.presence
      self.ctrt_ofcr_nm = ctrt_ofcr_nm.to_s.strip.presence
      self.ctrt_dept_cd = ctrt_dept_cd.to_s.strip.upcase.presence
      self.ctrt_dept_nm = ctrt_dept_nm.to_s.strip.presence
      self.loan_limt_over_yn_cd = normalize_yn(loan_limt_over_yn_cd, default_value: "N")
      self.vat_sctn_cd = vat_sctn_cd.to_s.strip.upcase.presence
      self.apv_mthd_cd = apv_mthd_cd.to_s.strip.upcase.presence
      self.apv_type_cd = apv_type_cd.to_s.strip.upcase.presence
      self.bilg_mthd_cd = bilg_mthd_cd.to_s.strip.upcase.presence
      self.dcsn_yn_cd = normalize_yn(dcsn_yn_cd, default_value: "N")
      self.use_yn_cd = normalize_yn(use_yn_cd, default_value: "Y")
      self.ctrt_chg_reason_cd = ctrt_chg_reason_cd.to_s.strip.presence
      self.op_area_cd = op_area_cd.to_s.strip.presence
      self.re_ctrt_cond_cd = re_ctrt_cond_cd.to_s.strip.presence
      self.ctrt_cnctr_cond_cd = ctrt_cnctr_cond_cd.to_s.strip.presence
      self.ctrt_cnctr_dtl_reason_cd = ctrt_cnctr_dtl_reason_cd.to_s.strip.presence
      self.pay_cond_cd = pay_cond_cd.to_s.strip.upcase.presence
      self.bzac_sctn_cd = bzac_sctn_cd.to_s.strip.upcase.presence
      self.work_step_no1_cd = work_step_no1_cd.to_s.strip.upcase.presence
      self.work_step_no2_cd = work_step_no2_cd.to_s.strip.upcase.presence
      self.remk = remk.to_s.strip.presence
    end

    def normalize_yn(value, default_value:)
      normalized = value.to_s.strip.upcase
      if normalized.present?
        normalized
      else
        default_value
      end
    end
end
