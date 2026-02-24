class OmCustomerSystemConfig < ApplicationRecord
  include Std::Auditable

  self.table_name = "om_customer_system_configs"

  validates :setup_unit_cd, presence: true, length: { maximum: 30 }
  validates :cust_cd, length: { maximum: 20 }
  validates :lclas_cd, presence: true, length: { maximum: 50 }
  validates :mclas_cd, presence: true, length: { maximum: 50 }
  validates :sclas_cd, presence: true, length: { maximum: 50 }
  validates :setup_sctn_cd, presence: true, length: { maximum: 50 }
  validates :module_nm, length: { maximum: 150 }, allow_blank: true
  validates :setup_value, length: { maximum: 200 }, allow_blank: true
  validates :use_yn, inclusion: { in: %w[Y N] }
  validates :lclas_cd, uniqueness: {
    scope: %i[setup_unit_cd cust_cd mclas_cd sclas_cd setup_sctn_cd],
    message: "동일 키의 설정이 이미 존재합니다."
  }

  validate :validate_customer_requirement

  before_validation :normalize_fields

  scope :ordered, -> { order(:setup_unit_cd, :cust_cd, :lclas_cd, :mclas_cd, :sclas_cd, :setup_sctn_cd) }

  private
    def normalize_fields
      self.setup_unit_cd = setup_unit_cd.to_s.strip.upcase
      self.cust_cd = cust_cd.to_s.strip.upcase
      self.lclas_cd = lclas_cd.to_s.strip.upcase
      self.mclas_cd = mclas_cd.to_s.strip.upcase
      self.sclas_cd = sclas_cd.to_s.strip.upcase
      self.setup_sctn_cd = setup_sctn_cd.to_s.strip.upcase
      self.module_nm = module_nm.to_s.strip.presence
      self.setup_value = setup_value.to_s.strip.presence
      self.use_yn = normalize_yn(use_yn, default_value: "Y")

      if setup_unit_cd == "SYSTEM"
        self.cust_cd = ""
      end

      # Legacy schema compatibility:
      # older environments still keep om_customer_system_configs columns used by previous implementation.
      if has_attribute?(:upper_grp_cd)
        self[:upper_grp_cd] = lclas_cd
      end
      if has_attribute?(:grp_cd)
        self[:grp_cd] = mclas_cd
      end
      if has_attribute?(:config_key)
        self[:config_key] = sclas_cd.presence || module_nm.to_s.strip.upcase.presence || "ITEM_NM"
      end
      if has_attribute?(:config_value)
        self[:config_value] = setup_value
      end
    end

    def validate_customer_requirement
      if setup_unit_cd == "CUSTOMER" && cust_cd.blank?
        errors.add(:cust_cd, :blank)
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
end
