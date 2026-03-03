class StdBusinessCertificate < ApplicationRecord
  include Std::Auditable

  self.table_name = "std_business_certificates"

  validates :bzac_cd, presence: true, uniqueness: true, length: { maximum: 20 }
  validates :compreg_slip, presence: true, length: { maximum: 30 }
  validates :bizman_yn_cd, presence: true, length: { maximum: 20 }
  validates :store_nm_cd, presence: true, length: { maximum: 200 }
  validates :rptr_nm_cd, presence: true, length: { maximum: 120 }
  validates :dup_bzac_yn_cd, inclusion: { in: %w[Y N] }
  validates :use_yn_cd, inclusion: { in: %w[Y N] }

  before_validation :normalize_fields

  scope :ordered, -> { order(:bzac_cd) }

  private
    def normalize_fields
      self.bzac_cd = bzac_cd.to_s.strip.upcase
      self.bzac_nm = bzac_nm.to_s.strip.presence
      self.compreg_slip = compreg_slip.to_s.gsub(/[^0-9]/, "")
      self.bizman_yn_cd = bizman_yn_cd.to_s.strip.upcase
      self.store_nm_cd = store_nm_cd.to_s.strip
      self.rptr_nm_cd = rptr_nm_cd.to_s.strip
      self.corp_reg_no_cd = corp_reg_no_cd.to_s.strip.presence
      self.bizcond_cd = bizcond_cd.to_s.strip.presence
      self.indstype_cd = indstype_cd.to_s.strip.presence
      self.dup_bzac_yn_cd = normalize_yn(dup_bzac_yn_cd, default_value: "N")
      self.zip_cd = zip_cd.to_s.strip.presence
      self.zipaddr_cd = zipaddr_cd.to_s.strip.presence
      self.dtl_addr_cd = dtl_addr_cd.to_s.strip.presence
      self.rmk = rmk.to_s.strip.presence
      self.attached_file_nm = attached_file_nm.to_s.strip.presence
      self.use_yn_cd = normalize_yn(use_yn_cd, default_value: "Y")
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
