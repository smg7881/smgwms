class WmWorkplace < ApplicationRecord
  self.table_name = "wm_workplaces"

  validates :workpl_cd, presence: true, uniqueness: true, length: { maximum: 50 }
  validates :workpl_nm, presence: true, length: { maximum: 100 }
  validates :workpl_type, length: { maximum: 50 }, allow_blank: true
  validates :client_cd, length: { maximum: 50 }, allow_blank: true
  validates :prop_cd, length: { maximum: 50 }, allow_blank: true
  validates :nation_cd, length: { maximum: 20 }, allow_blank: true
  validates :zip_cd, length: { maximum: 20 }, allow_blank: true
  validates :addr, length: { maximum: 300 }, allow_blank: true
  validates :addr_dtl, length: { maximum: 300 }, allow_blank: true
  validates :tel_no, length: { maximum: 30 }, allow_blank: true
  validates :fax_no, length: { maximum: 30 }, allow_blank: true
  validates :use_yn, inclusion: { in: %w[Y N] }

  before_validation :normalize_fields
  before_save :assign_audit_fields
  before_create :assign_create_fields

  scope :ordered, -> { order(:workpl_cd) }

  private
    def normalize_fields
      self.workpl_cd = workpl_cd.to_s.strip.upcase
      self.workpl_nm = workpl_nm.to_s.strip
      self.workpl_type = workpl_type.to_s.strip.upcase.presence
      self.client_cd = client_cd.to_s.strip.upcase.presence
      self.prop_cd = prop_cd.to_s.strip.upcase.presence
      self.nation_cd = nation_cd.to_s.strip.upcase.presence
      self.zip_cd = zip_cd.to_s.strip.presence
      self.addr = addr.to_s.strip.presence
      self.addr_dtl = addr_dtl.to_s.strip.presence
      self.tel_no = tel_no.to_s.strip.presence
      self.fax_no = fax_no.to_s.strip.presence
      self.remk = remk.to_s.strip.presence
      self.use_yn = use_yn.to_s.strip.upcase.presence || "Y"
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
