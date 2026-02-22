class StdReservedJob < ApplicationRecord
  include Std::Auditable

  self.table_name = "std_reserved_jobs"

  validates :sys_sctn_cd, presence: true, length: { maximum: 30 }
  validates :rsv_work_no, presence: true, uniqueness: true, length: { maximum: 20 }
  validates :rsv_work_nm_cd, presence: true, length: { maximum: 150 }
  validates :rsv_work_desc_cd, presence: true, length: { maximum: 300 }
  validates :rsv_work_cycle_cd, presence: true, length: { maximum: 30 }
  validates :use_yn_cd, inclusion: { in: %w[Y N] }

  before_validation :assign_rsv_work_no, on: :create
  before_validation :normalize_fields

  scope :ordered, -> { order(:sys_sctn_cd, :rsv_work_no) }

  private
    def assign_rsv_work_no
      if rsv_work_no.to_s.strip.present?
        return
      end

      max_num = self.class.where("rsv_work_no LIKE ?", "RW%")
                          .pluck(:rsv_work_no)
                          .filter_map do |code|
        raw = code.to_s.strip
        if raw.match?(/\ARW\d{6}\z/)
          raw[2..].to_i
        end
      end.max.to_i
      self.rsv_work_no = format("RW%06d", max_num + 1)
    end

    def normalize_fields
      self.sys_sctn_cd = sys_sctn_cd.to_s.strip.upcase
      self.rsv_work_no = rsv_work_no.to_s.strip.upcase
      self.rel_menu_cd = rel_menu_cd.to_s.strip.upcase.presence
      self.rel_menu_nm = rel_menu_nm.to_s.strip.presence
      self.rsv_work_nm_cd = rsv_work_nm_cd.to_s.strip
      self.rsv_work_desc_cd = rsv_work_desc_cd.to_s.strip
      self.rel_pgm_cd = rel_pgm_cd.to_s.strip.upcase.presence
      self.rel_pgm_nm = rel_pgm_nm.to_s.strip.presence
      self.pgm_sctn_cd = pgm_sctn_cd.to_s.strip.upcase.presence
      self.rsv_work_cycle_cd = rsv_work_cycle_cd.to_s.strip.upcase
      self.hms_unit_min = normalize_integer(hms_unit_min)
      self.rmk_cd = rmk_cd.to_s.strip.presence
      self.use_yn_cd = normalize_yn(use_yn_cd, default_value: "Y")
    end

    def normalize_integer(value)
      if value.to_s.strip.blank?
        nil
      else
        value.to_i
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
end
