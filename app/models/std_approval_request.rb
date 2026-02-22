class StdApprovalRequest < ApplicationRecord
  self.table_name = "std_approval_requests"

  validates :apv_req_no, presence: true, uniqueness: true, length: { maximum: 20 }
  validates :corp_cd, presence: true, length: { maximum: 20 }
  validates :menu_nm, presence: true, length: { maximum: 120 }
  validates :apv_reqr, presence: true, length: { maximum: 50 }
  validates :asmt_apver, presence: true, length: { maximum: 50 }
  validates :apv_stat_cd, presence: true, length: { maximum: 30 }
  validates :use_yn, inclusion: { in: %w[Y N] }

  before_validation :assign_apv_req_no, on: :create
  before_validation :normalize_fields
  before_save :assign_audit_fields
  before_create :assign_create_fields

  scope :ordered, -> { order(apv_req_ymd: :desc, apv_req_no: :desc) }

  private
    def assign_apv_req_no
      if apv_req_no.to_s.strip.present?
        return
      end

      prefix = Time.current.strftime("APR%Y%m%d")
      existing_numbers = self.class.where("apv_req_no LIKE ?", "#{prefix}%").pluck(:apv_req_no).map do |code|
        code.to_s.delete_prefix(prefix).to_i
      end
      next_number = existing_numbers.max.to_i + 1
      self.apv_req_no = format("%s%04d", prefix, next_number)
    end

    def normalize_fields
      self.apv_req_no = apv_req_no.to_s.strip.upcase
      self.corp_cd = corp_cd.to_s.strip.upcase
      self.menu_cd = menu_cd.to_s.strip.upcase.presence
      self.menu_nm = menu_nm.to_s.strip
      self.apv_reqr = apv_reqr.to_s.strip.upcase
      self.asmt_apver = asmt_apver.to_s.strip.upcase
      self.apver_chg = apver_chg.to_s.strip.upcase.presence
      self.user_cd = user_cd.to_s.strip.upcase.presence
      self.apv_req_conts = apv_req_conts.to_s.strip.presence
      self.apv_opi = apv_opi.to_s.strip.presence
      self.apv_stat_cd = apv_stat_cd.to_s.strip.upcase.presence || "REQUESTED"
      self.apv_type_cd = apv_type_cd.to_s.strip.upcase.presence
      self.use_yn = normalize_yn(use_yn, default_value: "Y")
      if apv_req_ymd.blank?
        self.apv_req_ymd = Time.current
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
