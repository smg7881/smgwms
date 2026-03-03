class StdWorkStep < ApplicationRecord
  self.table_name = "std_work_steps"

  validates :work_step_cd, presence: true, uniqueness: true, length: { maximum: 30 }
  validates :work_step_nm, presence: true, length: { maximum: 150 }
  validates :work_step_level1_cd, presence: true, length: { maximum: 30 }
  validates :work_step_level2_cd, presence: true, length: { maximum: 30 }
  validates :sort_seq, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :rmk_cd, length: { maximum: 500 }, allow_blank: true
  validates :use_yn_cd, inclusion: { in: %w[Y N] }
  validate :work_step_level2_matches_level1

  before_validation :normalize_fields
  before_save :assign_audit_fields
  before_create :assign_create_fields

  scope :ordered, -> { order(:sort_seq, :work_step_cd) }

  private
    def normalize_fields
      self.work_step_cd = work_step_cd.to_s.strip.upcase
      self.work_step_nm = work_step_nm.to_s.strip
      self.work_step_level1_cd = work_step_level1_cd.to_s.strip.upcase
      self.work_step_level2_cd = work_step_level2_cd.to_s.strip.upcase
      self.conts_cd = conts_cd.to_s.strip.presence
      self.rmk_cd = rmk_cd.to_s.strip.presence
      self.use_yn_cd = normalize_yn(use_yn_cd, default_value: "Y")

      if sort_seq.nil?
        self.sort_seq = 0
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

    def work_step_level2_matches_level1
      if work_step_level1_cd.blank? || work_step_level2_cd.blank?
        return
      end

      if !AdmCodeDetail.active.exists?(code: "07", detail_code: work_step_level1_cd)
        errors.add(:work_step_level1_cd, "유효한 작업단계 Level1 코드가 아닙니다.")
      end

      if !AdmCodeDetail.active.exists?(code: "08", detail_code: work_step_level2_cd, upper_detail_code: work_step_level1_cd)
        errors.add(:work_step_level2_cd, "선택한 작업단계 Level1에 매핑되지 않은 코드입니다.")
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
