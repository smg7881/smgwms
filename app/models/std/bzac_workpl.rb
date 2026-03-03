class StdBzacWorkpl < ApplicationRecord
  self.table_name = "std_bzac_workpl"

  belongs_to :client,
             class_name: "StdBzacMst",
             foreign_key: :bzac_cd,
             primary_key: :bzac_cd,
             inverse_of: :workpls,
             optional: true

  validates :bzac_cd, presence: true, length: { maximum: 20 }
  validates :seq_cd, presence: true
  validates :seq_cd, uniqueness: { scope: :bzac_cd }
  validates :workpl_nm_cd, presence: true, length: { maximum: 120 }
  validates :workpl_sctn_cd, length: { maximum: 50 }, allow_blank: true
  validates :ofcr_cd, length: { maximum: 50 }, allow_blank: true
  validates :use_yn_cd, inclusion: { in: %w[Y N] }

  before_validation :normalize_fields
  before_save :assign_audit_fields
  before_create :assign_create_fields

  scope :ordered, -> { order(:bzac_cd, :seq_cd) }

  private
    def normalize_fields
      self.bzac_cd = bzac_cd.to_s.strip.upcase
      self.workpl_nm_cd = workpl_nm_cd.to_s.strip
      self.workpl_sctn_cd = workpl_sctn_cd.to_s.strip.upcase.presence
      self.ofcr_cd = ofcr_cd.to_s.strip.upcase.presence
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
