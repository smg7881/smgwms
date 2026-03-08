class Wm::GiPrar < ApplicationRecord
  self.table_name = "wm_gi_prars"
  self.primary_key = "gi_prar_no"

  GI_STAT_INSTRUCTED = "10"
  GI_STAT_ASSIGNED = "20"
  GI_STAT_PICKED = "30"
  GI_STAT_CONFIRMED = "40"

  has_many :details, class_name: "Wm::GiPrarDetail", foreign_key: "gi_prar_no", dependent: :destroy
  has_many :picks, class_name: "Wm::GiPick", foreign_key: "gi_prar_no", dependent: :destroy

  validates :gi_prar_no, presence: true, uniqueness: true
  validates :workpl_cd, presence: true
  validates :corp_cd, presence: true
  validates :cust_cd, presence: true
  validates :gi_stat_cd, presence: true

  before_validation :normalize_fields
  before_save :assign_update_audit_fields
  before_create :assign_create_audit_fields

  scope :ordered, -> { order(gi_prar_no: :desc) }

  def instructed?
    gi_stat_cd == GI_STAT_INSTRUCTED
  end

  def assigned?
    gi_stat_cd == GI_STAT_ASSIGNED
  end

  def picked?
    gi_stat_cd == GI_STAT_PICKED
  end

  def confirmed?
    gi_stat_cd == GI_STAT_CONFIRMED
  end

  private
    def normalize_fields
      self.gi_prar_no = gi_prar_no.to_s.strip.presence
      self.workpl_cd = workpl_cd.to_s.strip.upcase.presence
      self.corp_cd = corp_cd.to_s.strip.upcase.presence
      self.cust_cd = cust_cd.to_s.strip.upcase.presence
      self.gi_type_cd = gi_type_cd.to_s.strip.upcase.presence
      self.gi_stat_cd = gi_stat_cd.to_s.strip.upcase.presence || GI_STAT_INSTRUCTED
      self.ord_no = ord_no.to_s.strip.presence
      self.exec_ord_no = exec_ord_no.to_s.strip.presence
      self.asign_no = asign_no.to_s.strip.presence
      self.car_no = car_no.to_s.strip.presence
      self.driver_nm = driver_nm.to_s.strip.presence
      self.driver_telno = driver_telno.to_s.strip.presence
      self.transco_cd = transco_cd.to_s.strip.presence
      self.rmk = rmk.to_s.strip.presence
    end

    def assign_update_audit_fields
      self.update_by = current_actor
      self.update_time = Time.current
    end

    def assign_create_audit_fields
      self.create_by = current_actor
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
