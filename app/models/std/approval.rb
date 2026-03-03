class StdApproval < ApplicationRecord
  self.table_name = "std_approvals"

  validates :corp_cd, presence: true, length: { maximum: 20 }
  validates :menu_cd, presence: true, length: { maximum: 30 }
  validates :menu_nm, presence: true, length: { maximum: 120 }
  validates :menu_cd, uniqueness: { scope: :corp_cd }
  validates :asmt_apver_yn, inclusion: { in: %w[Y N] }
  validates :apv_delegt_yn, inclusion: { in: %w[Y N] }
  validates :use_yn, inclusion: { in: %w[Y N] }

  before_validation :normalize_fields
  before_save :assign_audit_fields
  before_create :assign_create_fields

  scope :ordered, -> { order(:corp_cd, :menu_cd) }

  private
    def normalize_fields
      self.corp_cd = corp_cd.to_s.strip.upcase
      self.corp_nm = corp_nm.to_s.strip.presence
      self.menu_cd = menu_cd.to_s.strip.upcase
      self.menu_nm = menu_nm.to_s.strip
      self.table_cd = table_cd.to_s.strip.upcase.presence
      self.col1_cd = col1_cd.to_s.strip.upcase.presence
      self.col2_cd = col2_cd.to_s.strip.upcase.presence
      self.col3_cd = col3_cd.to_s.strip.upcase.presence
      self.col4_cd = col4_cd.to_s.strip.upcase.presence
      self.col5_cd = col5_cd.to_s.strip.upcase.presence
      self.asmt_apver_yn = normalize_yn(asmt_apver_yn, default_value: "Y")
      self.chrg_apver = chrg_apver.to_s.strip.upcase.presence
      self.not_asmt_apver_resp = not_asmt_apver_resp.to_s.strip.upcase.presence
      self.apv_type_cd = apv_type_cd.to_s.strip.upcase.presence
      self.apv_delegt_yn = normalize_yn(apv_delegt_yn, default_value: "N")
      self.apv_delegate = apv_delegate.to_s.strip.upcase.presence
      self.rmk = rmk.to_s.strip.presence
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
