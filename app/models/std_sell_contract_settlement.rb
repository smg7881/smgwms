class StdSellContractSettlement < ApplicationRecord
  include Std::Auditable

  self.table_name = "std_sell_contract_settlements"

  belongs_to :sell_contract,
             class_name: "StdSellContract",
             foreign_key: :sell_contract_id,
             inverse_of: :settlements

  validates :sell_contract_id, presence: true
  validates :seq_no, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :seq_no, uniqueness: { scope: :sell_contract_id }
  validates :use_yn_cd, inclusion: { in: %w[Y N] }

  before_validation :normalize_fields

  scope :ordered, -> { order(:seq_no) }

  private
    def normalize_fields
      self.fnc_or_cd = fnc_or_cd.to_s.strip.upcase.presence
      self.fnc_or_nm = fnc_or_nm.to_s.strip.presence
      self.acnt_no_cd = acnt_no_cd.to_s.strip.presence
      self.dpstr_nm = dpstr_nm.to_s.strip.presence
      self.mon_cd = mon_cd.to_s.strip.upcase.presence
      self.aply_fnc_or_cd = aply_fnc_or_cd.to_s.strip.upcase.presence
      self.aply_fnc_or_nm = aply_fnc_or_nm.to_s.strip.presence
      self.anno_dgrcnt = anno_dgrcnt.to_s.strip.upcase.presence
      self.exrt_aply_std_cd = exrt_aply_std_cd.to_s.strip.upcase.presence
      self.main_bank_yn_cd = main_bank_yn_cd.to_s.strip.upcase.presence
      self.exca_ofcr_cd = exca_ofcr_cd.to_s.strip.upcase.presence
      self.exca_ofcr_nm = exca_ofcr_nm.to_s.strip.presence
      self.use_yn_cd = normalize_yn(use_yn_cd)
      self.remk = remk.to_s.strip.presence
    end

    def normalize_yn(value)
      normalized = value.to_s.strip.upcase
      if normalized.present?
        normalized
      else
        "Y"
      end
    end
end
