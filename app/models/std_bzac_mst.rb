class StdBzacMst < ApplicationRecord
  self.table_name = "std_bzac_mst"

  has_many :ofcrs,
           class_name: "StdBzacOfcr",
           foreign_key: :bzac_cd,
           primary_key: :bzac_cd,
           inverse_of: :client,
           dependent: :delete_all
  has_many :workpls,
           class_name: "StdBzacWorkpl",
           foreign_key: :bzac_cd,
           primary_key: :bzac_cd,
           inverse_of: :client,
           dependent: :delete_all

  validates :bzac_cd, presence: true, uniqueness: true, length: { maximum: 20 }
  validates :bzac_nm, presence: true, length: { maximum: 200 }
  validates :mngt_corp_cd, presence: true, length: { maximum: 50 }
  validates :bizman_no, presence: true, length: { maximum: 20 }
  validates :bzac_sctn_grp_cd, presence: true, length: { maximum: 50 }
  validates :bzac_sctn_cd, presence: true, length: { maximum: 50 }
  validates :bzac_kind_cd, presence: true, length: { maximum: 50 }
  validates :ctry_cd, presence: true, length: { maximum: 10 }
  validates :rpt_sales_emp_cd, presence: true, length: { maximum: 50 }
  validates :aply_strt_day_cd, presence: true
  validates :use_yn_cd, inclusion: { in: %w[Y N] }
  validates :tpl_logis_yn_cd, inclusion: { in: %w[Y N] }
  validates :if_yn_cd, inclusion: { in: %w[Y N] }
  validates :branch_yn_cd, inclusion: { in: %w[Y N] }
  validates :sell_bzac_yn_cd, inclusion: { in: %w[Y N] }
  validates :pur_bzac_yn_cd, inclusion: { in: %w[Y N] }
  validates :elec_taxbill_yn_cd, inclusion: { in: %w[Y N] }

  validate :bizman_no_format
  validate :bizman_no_uniqueness_rule

  before_validation :assign_bzac_cd, on: :create
  before_validation :normalize_fields
  before_save :assign_audit_fields
  before_create :assign_create_fields

  scope :ordered, -> { order(:bzac_cd) }

  private
    def assign_bzac_cd
      if bzac_cd.to_s.strip.present?
        return
      end

      numeric_codes = self.class.pluck(:bzac_cd).filter_map do |code|
        stripped = code.to_s.strip
        if stripped.match?(/\A\d+\z/)
          stripped.to_i
        end
      end
      next_number = numeric_codes.max.to_i + 1
      self.bzac_cd = format("%08d", next_number)
    end

    def normalize_fields
      self.bzac_cd = bzac_cd.to_s.strip.upcase
      self.bzac_nm = bzac_nm.to_s.strip
      self.mngt_corp_cd = mngt_corp_cd.to_s.strip.upcase
      self.mngt_corp_nm = mngt_corp_nm.to_s.strip.presence
      self.bizman_no = bizman_no.to_s.gsub(/[^0-9]/, "")
      self.bzac_sctn_grp_cd = bzac_sctn_grp_cd.to_s.strip.upcase
      self.bzac_sctn_cd = bzac_sctn_cd.to_s.strip.upcase
      self.bzac_kind_cd = bzac_kind_cd.to_s.strip.upcase
      self.upper_bzac_cd = upper_bzac_cd.to_s.strip.upcase.presence
      self.rpt_bzac_cd = rpt_bzac_cd.to_s.strip.upcase.presence
      self.ctry_cd = ctry_cd.to_s.strip.upcase.presence || "KR"
      self.tpl_logis_yn_cd = normalize_yn(tpl_logis_yn_cd, default_value: "N")
      self.if_yn_cd = normalize_yn(if_yn_cd, default_value: "N")
      self.branch_yn_cd = normalize_yn(branch_yn_cd, default_value: "N")
      self.sell_bzac_yn_cd = normalize_yn(sell_bzac_yn_cd, default_value: "Y")
      self.pur_bzac_yn_cd = normalize_yn(pur_bzac_yn_cd, default_value: "Y")
      self.bilg_bzac_cd = bilg_bzac_cd.to_s.strip.upcase.presence
      self.elec_taxbill_yn_cd = normalize_yn(elec_taxbill_yn_cd, default_value: "N")
      self.fnc_or_cd = fnc_or_cd.to_s.strip.upcase.presence
      self.acnt_no_cd = acnt_no_cd.to_s.strip.presence
      self.zip_cd = zip_cd.to_s.strip.presence
      self.addr_cd = addr_cd.to_s.strip.presence
      self.addr_dtl_cd = addr_dtl_cd.to_s.strip.presence
      self.rpt_sales_emp_cd = rpt_sales_emp_cd.to_s.strip.upcase
      self.rpt_sales_emp_nm = rpt_sales_emp_nm.to_s.strip.presence
      self.aply_strt_day_cd = aply_strt_day_cd.presence || Date.current
      self.use_yn_cd = normalize_yn(use_yn_cd, default_value: "Y")
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

    def bizman_no_format
      digits = bizman_no.to_s
      if digits.blank?
        return
      end

      if !digits.match?(/\A\d{10}\z/)
        errors.add(:bizman_no, :invalid_10_digits)
      end
    end

    def bizman_no_uniqueness_rule
      if bizman_no.blank? || rpt_bzac_cd.present?
        return
      end

      duplicate_scope = self.class.where(bizman_no: bizman_no)
      if persisted?
        duplicate_scope = duplicate_scope.where.not(id: id)
      end

      duplicate_exists = duplicate_scope.where(rpt_bzac_cd: [ nil, "" ]).exists?
      if duplicate_exists
        errors.add(:bizman_no, :not_unique_without_representative)
      end
    end

    def assign_audit_fields
      actor = current_actor
      self.update_by = actor
      self.update_time = Time.current
    end

    def assign_create_fields
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
