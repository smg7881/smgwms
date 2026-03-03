class StdWorkRouting < ApplicationRecord
  self.table_name = "std_work_routings"

  has_many :steps,
           class_name: "StdWorkRoutingStep",
           foreign_key: :wrk_rt_cd,
           primary_key: :wrk_rt_cd,
           inverse_of: :work_routing,
           dependent: :delete_all

  validates :wrk_rt_cd, presence: true, uniqueness: true, length: { maximum: 20 }
  validates :wrk_rt_nm, presence: true, length: { maximum: 150 }
  validates :hwajong_cd, length: { maximum: 30 }, allow_blank: true
  validates :wrk_type1_cd, length: { maximum: 30 }, allow_blank: true
  validates :wrk_type2_cd, length: { maximum: 30 }, allow_blank: true
  validates :rmk_cd, length: { maximum: 500 }, allow_blank: true
  validates :use_yn_cd, inclusion: { in: %w[Y N] }

  before_validation :assign_wrt_rt_cd, on: :create
  before_validation :normalize_fields
  before_save :assign_audit_fields
  before_create :assign_create_fields

  scope :ordered, -> { order(:wrk_rt_cd) }

  private
    def assign_wrt_rt_cd
      if wrk_rt_cd.to_s.strip.present?
        return
      end

      numeric_codes = self.class.pluck(:wrk_rt_cd).filter_map do |code|
        stripped = code.to_s.strip
        if stripped.match?(/\A\d+\z/)
          stripped.to_i
        end
      end
      next_number = numeric_codes.max.to_i + 1
      self.wrk_rt_cd = format("%05d", next_number)
    end

    def normalize_fields
      self.wrk_rt_cd = wrk_rt_cd.to_s.strip.upcase
      self.wrk_rt_nm = wrk_rt_nm.to_s.strip
      self.hwajong_cd = hwajong_cd.to_s.strip.upcase.presence
      self.wrk_type1_cd = wrk_type1_cd.to_s.strip.upcase.presence
      self.wrk_type2_cd = wrk_type2_cd.to_s.strip.upcase.presence
      self.use_yn_cd = normalize_yn(use_yn_cd, default_value: "Y")
      self.rmk_cd = rmk_cd.to_s.strip.presence
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
