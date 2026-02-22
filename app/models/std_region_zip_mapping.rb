class StdRegionZipMapping < ApplicationRecord
  self.table_name = "std_region_zip_mappings"

  validates :regn_cd, presence: true, length: { maximum: 10 }
  validates :ctry_cd, presence: true, length: { maximum: 10 }
  validates :zipcd, presence: true, length: { maximum: 20 }
  validates :seq_no, presence: true, numericality: { only_integer: true }
  validates :sort_seq, numericality: { only_integer: true }
  validates :seq_no, uniqueness: { scope: [ :regn_cd, :ctry_cd, :zipcd ] }

  before_validation :normalize_fields
  before_save :assign_audit_fields
  before_create :assign_create_fields

  scope :ordered, -> { order(:regn_cd, :sort_seq, :ctry_cd, :zipcd, :seq_no) }

  private
    def normalize_fields
      self.regn_cd = regn_cd.to_s.strip.upcase
      self.ctry_cd = ctry_cd.to_s.strip.upcase
      self.zipcd = zipcd.to_s.strip.upcase
      self.seq_no = seq_no.to_i
      self.sort_seq = sort_seq.to_i
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
