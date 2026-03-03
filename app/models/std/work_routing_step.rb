class StdWorkRoutingStep < ApplicationRecord
  self.table_name = "std_work_routing_steps"

  belongs_to :work_routing,
             class_name: "StdWorkRouting",
             foreign_key: :wrk_rt_cd,
             primary_key: :wrk_rt_cd,
             inverse_of: :steps

  validates :wrk_rt_cd, presence: true, length: { maximum: 20 }
  validates :seq_no, presence: true, numericality: { only_integer: true, greater_than: 0 }, uniqueness: { scope: :wrk_rt_cd }
  validates :work_step_cd, presence: true, length: { maximum: 30 }
  validates :work_step_level1_cd, length: { maximum: 30 }, allow_blank: true
  validates :work_step_level2_cd, length: { maximum: 30 }, allow_blank: true
  validates :rmk_cd, length: { maximum: 500 }, allow_blank: true
  validates :use_yn_cd, inclusion: { in: %w[Y N] }

  before_validation :normalize_fields
  before_validation :assign_seq_no, on: :create
  before_save :assign_audit_fields
  before_create :assign_create_fields

  scope :ordered, -> { order(:seq_no) }
  scope :active, -> { where(use_yn_cd: "Y") }

  private
    def normalize_fields
      self.wrk_rt_cd = wrk_rt_cd.to_s.strip.upcase
      self.work_step_cd = work_step_cd.to_s.strip.upcase
      self.work_step_level1_cd = work_step_level1_cd.to_s.strip.upcase.presence
      self.work_step_level2_cd = work_step_level2_cd.to_s.strip.upcase.presence
      self.use_yn_cd = normalize_yn(use_yn_cd, default_value: "Y")
      self.rmk_cd = rmk_cd.to_s.strip.presence
    end

    def assign_seq_no
      if seq_no.present?
        return
      end

      return if wrk_rt_cd.blank?

      max_seq = self.class.where(wrk_rt_cd: wrk_rt_cd).maximum(:seq_no).to_i
      self.seq_no = max_seq + 1
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
