class OmOrderOfficer < ApplicationRecord
  include Std::Auditable

  self.table_name = "om_order_officers"

  validates :ord_chrg_dept_cd, presence: true, length: { maximum: 50 }
  validates :ord_chrg_dept_nm, length: { maximum: 100 }, allow_blank: true
  validates :cust_cd, presence: true, length: { maximum: 20 }
  validates :cust_nm, length: { maximum: 120 }, allow_blank: true
  validates :exp_imp_dom_sctn_cd, presence: true, length: { maximum: 30 }
  validates :ofcr_cd, presence: true, length: { maximum: 30 }
  validates :ofcr_nm, presence: true, length: { maximum: 100 }
  validates :tel_no, length: { maximum: 30 }, allow_blank: true
  validates :mbp_no, length: { maximum: 30 }, allow_blank: true
  validates :use_yn, inclusion: { in: %w[Y N] }
  validates :ofcr_cd, uniqueness: {
    scope: %i[ord_chrg_dept_cd cust_cd exp_imp_dom_sctn_cd],
    message: "동일한 오더담당자 정보가 이미 존재합니다."
  }

  before_validation :normalize_fields

  scope :ordered, -> { order(:ord_chrg_dept_cd, :cust_cd, :exp_imp_dom_sctn_cd, :ofcr_cd) }

  private
    def normalize_fields
      self.ord_chrg_dept_cd = ord_chrg_dept_cd.to_s.strip.upcase
      self.ord_chrg_dept_nm = ord_chrg_dept_nm.to_s.strip.presence
      self.cust_cd = cust_cd.to_s.strip.upcase
      self.cust_nm = cust_nm.to_s.strip.presence
      self.exp_imp_dom_sctn_cd = exp_imp_dom_sctn_cd.to_s.strip.upcase
      self.ofcr_cd = ofcr_cd.to_s.strip.upcase
      self.ofcr_nm = ofcr_nm.to_s.strip
      self.tel_no = tel_no.to_s.strip.presence
      self.mbp_no = mbp_no.to_s.strip.presence
      self.use_yn = normalize_yn(use_yn, default_value: "Y")
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
