class StdSellbuyAttribute < ApplicationRecord
  include Std::Auditable

  self.table_name = "std_sellbuy_attributes"
  attr_accessor :upper_sellbuy_attr_nm

  YN_COLUMNS = %i[
    sell_yn_cd pur_yn_cd tran_yn_cd fis_air_yn_cd strg_yn_cd
    cgwrk_yn_cd fis_shpng_yn_cd dc_extr_yn_cd tax_payfor_yn_cd
    lumpsum_yn_cd dcnct_reg_pms_yn_cd use_yn_cd
  ].freeze

  validates :corp_cd, presence: true, length: { maximum: 20 }
  validates :sellbuy_attr_cd, presence: true, uniqueness: true, length: { maximum: 20 }
  validates :sellbuy_attr_nm, presence: true, length: { maximum: 150 }
  validates :rdtn_nm, presence: true, length: { maximum: 120 }
  validates :sellbuy_attr_eng_nm, presence: true, length: { maximum: 150 }
  validates :sellbuy_sctn_cd, length: { maximum: 30 }, allow_blank: true
  validates :upper_sellbuy_attr_cd, length: { maximum: 20 }, allow_blank: true
  validates :sell_dr_acct_cd, length: { maximum: 30 }, allow_blank: true
  validates :sell_cr_acct_cd, length: { maximum: 30 }, allow_blank: true
  validates :pur_dr_acct_cd, length: { maximum: 30 }, allow_blank: true
  validates :pur_cr_acct_cd, length: { maximum: 30 }, allow_blank: true
  validates :sys_sctn_cd, length: { maximum: 30 }, allow_blank: true
  validates :ndcsn_sell_cr_acct_cd, length: { maximum: 30 }, allow_blank: true
  validates :ndcsn_cost_dr_acct_cd, length: { maximum: 30 }, allow_blank: true
  validates :rmk_cd, length: { maximum: 500 }, allow_blank: true
  validate :upper_attribute_not_self

  YN_COLUMNS.each do |field|
    validates field, inclusion: { in: %w[Y N] }
  end

  before_validation :assign_sellbuy_attr_cd, on: :create
  before_validation :normalize_fields

  scope :ordered, -> { order(:corp_cd, :sellbuy_attr_cd) }

  class << self
    def next_sellbuy_attr_cd
      numeric_codes = pluck(:sellbuy_attr_cd).filter_map do |code|
        stripped = code.to_s.strip
        if stripped.match?(/\A\d+\z/)
          stripped.to_i
        end
      end

      format("%08d", numeric_codes.max.to_i + 1)
    end
  end

  private
    def assign_sellbuy_attr_cd
      if sellbuy_attr_cd.to_s.strip.present?
        return
      end

      self.sellbuy_attr_cd = self.class.next_sellbuy_attr_cd
    end

    def normalize_fields
      self.corp_cd = corp_cd.to_s.strip.upcase
      self.sellbuy_sctn_cd = sellbuy_sctn_cd.to_s.strip.upcase.presence
      self.sellbuy_attr_cd = sellbuy_attr_cd.to_s.strip.upcase
      self.sellbuy_attr_nm = sellbuy_attr_nm.to_s.strip
      self.rdtn_nm = rdtn_nm.to_s.strip
      self.sellbuy_attr_eng_nm = sellbuy_attr_eng_nm.to_s.strip
      self.upper_sellbuy_attr_cd = upper_sellbuy_attr_cd.to_s.strip.upcase.presence

      self.sell_dr_acct_cd = sell_dr_acct_cd.to_s.strip.upcase.presence
      self.sell_cr_acct_cd = sell_cr_acct_cd.to_s.strip.upcase.presence
      self.pur_dr_acct_cd = pur_dr_acct_cd.to_s.strip.upcase.presence
      self.pur_cr_acct_cd = pur_cr_acct_cd.to_s.strip.upcase.presence
      self.sys_sctn_cd = sys_sctn_cd.to_s.strip.upcase.presence
      self.ndcsn_sell_cr_acct_cd = ndcsn_sell_cr_acct_cd.to_s.strip.upcase.presence
      self.ndcsn_cost_dr_acct_cd = ndcsn_cost_dr_acct_cd.to_s.strip.upcase.presence
      self.rmk_cd = rmk_cd.to_s.strip.presence

      YN_COLUMNS.each do |field|
        self[field] = normalize_yn(self[field], default_value: field == :use_yn_cd ? "Y" : "N")
      end
    end

    def normalize_yn(value, default_value:)
      normalized = value.to_s.strip.upcase
      if normalized.present?
        normalized
      else
        default_value
      end
    end

    def upper_attribute_not_self
      if sellbuy_attr_cd.present? && upper_sellbuy_attr_cd.present? && sellbuy_attr_cd == upper_sellbuy_attr_cd
        errors.add(:upper_sellbuy_attr_cd, "상위매출입항목코드는 자기 자신과 같을 수 없습니다.")
      end
    end
end
