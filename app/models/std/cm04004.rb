class StdCm04004 < ApplicationRecord
  self.table_name = "std_cm04004"

  validates :bzac_cd, presence: true, length: { maximum: 20 }
  validates :hist_seq, presence: true
  validates :changed_col_nm, presence: true, length: { maximum: 100 }
  validates :changed_by, length: { maximum: 50 }, allow_blank: true

  before_validation :normalize_fields
  before_save :assign_audit_fields
  before_create :assign_create_fields

  scope :ordered, -> { order(:bzac_cd, :hist_seq) }

  class << self
    def next_hist_seq_for(bzac_cd)
      where(bzac_cd: bzac_cd.to_s.strip.upcase).maximum(:hist_seq).to_i + 1
    end
  end

  private
    def normalize_fields
      self.bzac_cd = bzac_cd.to_s.strip.upcase
      self.changed_col_nm = changed_col_nm.to_s.strip
      self.changed_by = changed_by.to_s.strip.presence
      self.changed_at = changed_at.presence || Time.current
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
