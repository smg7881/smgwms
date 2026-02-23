class StdSellContractChangeHistory < ApplicationRecord
  include Std::Auditable

  self.table_name = "std_sell_contract_change_histories"

  belongs_to :sell_contract,
             class_name: "StdSellContract",
             foreign_key: :sell_contract_id,
             inverse_of: :change_histories

  validates :sell_contract_id, presence: true
  validates :seq_no, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :seq_no, uniqueness: { scope: :sell_contract_id }
  validates :chg_tbl_nm, presence: true, length: { maximum: 100 }
  validates :chg_col_nm, presence: true, length: { maximum: 100 }

  before_validation :normalize_fields

  scope :ordered, -> { order(:seq_no) }

  class << self
    def next_hist_seq_for(sell_contract_id)
      where(sell_contract_id: sell_contract_id).maximum(:seq_no).to_i + 1
    end
  end

  private
    def normalize_fields
      self.chg_tbl_nm = chg_tbl_nm.to_s.strip
      self.chg_col_nm = chg_col_nm.to_s.strip
      self.regr_cd = regr_cd.to_s.strip.presence
      self.chg_date = chg_date.presence || Time.current
    end
end
