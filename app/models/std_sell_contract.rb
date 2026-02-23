class StdSellContract < ApplicationRecord
  include Std::Auditable

  self.table_name = "std_sell_contracts"

  has_many :settlements,
           class_name: "StdSellContractSettlement",
           foreign_key: :sell_contract_id,
           inverse_of: :sell_contract,
           dependent: :delete_all
  has_many :change_histories,
           class_name: "StdSellContractChangeHistory",
           foreign_key: :sell_contract_id,
           inverse_of: :sell_contract,
           dependent: :delete_all

  validates :bzac_cd, presence: true, length: { maximum: 20 }
  validates :sell_ctrt_no, presence: true, uniqueness: true, length: { maximum: 30 }
  validates :sell_ctrt_nm, presence: true, length: { maximum: 200 }
  validates :bizman_no, presence: true, length: { maximum: 20 }
  validates :ctrt_sctn_cd, presence: true, length: { maximum: 30 }
  validates :ctrt_kind_cd, presence: true, length: { maximum: 30 }
  validates :use_yn_cd, inclusion: { in: %w[Y N] }
  validates :loan_limt_over_yn_cd, inclusion: { in: %w[Y N] }
  validates :dcsn_yn_cd, inclusion: { in: %w[Y N] }

  before_validation :assign_sell_ctrt_no, on: :create
  before_validation :normalize_fields

  scope :ordered, -> { order(:sell_ctrt_no) }

  class << self
    def next_sell_ctrt_no
      numbers = pluck(:sell_ctrt_no).filter_map do |code|
        normalized = code.to_s.strip
        if normalized.match?(/\ASC\d+\z/)
          normalized.delete_prefix("SC").to_i
        end
      end

      "SC#{format('%08d', numbers.max.to_i + 1)}"
    end
  end

  private
    def assign_sell_ctrt_no
      if sell_ctrt_no.to_s.strip.present?
        return
      end

      self.sell_ctrt_no = self.class.next_sell_ctrt_no
    end

    def normalize_fields
      self.corp_cd = corp_cd.to_s.strip.upcase.presence
      self.bzac_cd = bzac_cd.to_s.strip.upcase
      self.sell_ctrt_no = sell_ctrt_no.to_s.strip.upcase
      self.sell_ctrt_nm = sell_ctrt_nm.to_s.strip
      self.bizman_no = bizman_no.to_s.gsub(/[^0-9]/, "")
      self.ctrt_sctn_cd = ctrt_sctn_cd.to_s.strip.upcase
      self.ctrt_kind_cd = ctrt_kind_cd.to_s.strip.upcase
      self.bef_ctrt_no = bef_ctrt_no.to_s.strip.upcase.presence
      self.ctrt_dept_cd = ctrt_dept_cd.to_s.strip.upcase.presence
      self.ctrt_dept_nm = ctrt_dept_nm.to_s.strip.presence
      self.ctrt_cnctr_reason_cd = ctrt_cnctr_reason_cd.to_s.strip.upcase.presence
      self.indgrp_cd = indgrp_cd.to_s.strip.upcase.presence
      self.loan_limt_over_yn_cd = normalize_yn(loan_limt_over_yn_cd, default_value: "N")
      self.vat_sctn_cd = vat_sctn_cd.to_s.strip.upcase.presence
      self.apv_mthd_cd = apv_mthd_cd.to_s.strip.upcase.presence
      self.apv_type_cd = apv_type_cd.to_s.strip.upcase.presence
      self.bilg_mthd_cd = bilg_mthd_cd.to_s.strip.upcase.presence
      self.dcsn_yn_cd = normalize_yn(dcsn_yn_cd, default_value: "N")
      self.use_yn_cd = normalize_yn(use_yn_cd, default_value: "Y")
      self.ctrt_amt_chg_reason = ctrt_amt_chg_reason.to_s.strip.presence
      self.main_rsbt_clause = main_rsbt_clause.to_s.strip.presence
      self.re_ctrt_cond = re_ctrt_cond.to_s.strip.presence
      self.ctrt_cnctr_cond = ctrt_cnctr_cond.to_s.strip.presence
      self.ctrt_cnctr_dtl_reason = ctrt_cnctr_dtl_reason.to_s.strip.presence
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
