class StdWorkplace < ApplicationRecord
  self.table_name = "std_workplaces"

  validates :corp_cd, presence: true, length: { maximum: 20 }
  validates :workpl_cd, presence: true, uniqueness: true, length: { maximum: 20 }
  validates :dept_cd, presence: true, length: { maximum: 50 }
  validates :workpl_nm, presence: true, length: { maximum: 120 }
  validates :workpl_sctn_cd, presence: true, length: { maximum: 50 }
  validates :wm_yn_cd, inclusion: { in: %w[Y N] }
  validates :use_yn_cd, inclusion: { in: %w[Y N] }

  before_validation :assign_workpl_cd, on: :create
  before_validation :normalize_fields
  before_save :assign_audit_fields
  before_create :assign_create_fields

  scope :ordered, -> { order(:corp_cd, :workpl_cd) }

  private
    def assign_workpl_cd
      if workpl_cd.to_s.strip.present?
        return
      end

      numeric_codes = self.class.pluck(:workpl_cd).filter_map do |code|
        stripped = code.to_s.strip
        if stripped.match?(/\A\d+\z/)
          stripped.to_i
        end
      end
      next_number = numeric_codes.max.to_i + 1
      self.workpl_cd = format("%08d", next_number)
    end

    def normalize_fields
      self.corp_cd = corp_cd.to_s.strip.upcase
      self.workpl_cd = workpl_cd.to_s.strip.upcase
      self.upper_workpl_cd = upper_workpl_cd.to_s.strip.upcase.presence
      self.dept_cd = dept_cd.to_s.strip.upcase
      self.workpl_nm = workpl_nm.to_s.strip
      self.workpl_sctn_cd = workpl_sctn_cd.to_s.strip.upcase
      self.capa_spec_unit_cd = capa_spec_unit_cd.to_s.strip.upcase.presence
      self.dimem_spec_unit_cd = dimem_spec_unit_cd.to_s.strip.upcase.presence
      self.wm_yn_cd = normalize_yn(wm_yn_cd, default_value: "N")
      self.bzac_cd = bzac_cd.to_s.strip.upcase.presence
      self.ctry_cd = ctry_cd.to_s.strip.upcase.presence
      self.zip_cd = zip_cd.to_s.strip.presence
      self.addr_cd = addr_cd.to_s.strip.presence
      self.dtl_addr_cd = dtl_addr_cd.to_s.strip.presence
      self.use_yn_cd = normalize_yn(use_yn_cd, default_value: "Y")
      self.remk_cd = remk_cd.to_s.strip.presence
    end

    def normalize_yn(value, default_value:)
      normalized = value.to_s.strip.upcase
      if normalized.present?
        normalized
      else
        default_value
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
