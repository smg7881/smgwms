class StdZipCode < ApplicationRecord
  include Std::Auditable

  self.table_name = "std_zip_codes"

  validates :ctry_cd, presence: true, length: { maximum: 10 }
  validates :zipcd, presence: true, length: { maximum: 20 }
  validates :seq_no, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :seq_no, uniqueness: { scope: [ :ctry_cd, :zipcd ] }
  validates :use_yn_cd, inclusion: { in: %w[Y N] }

  before_validation :normalize_fields

  scope :ordered, -> { order(:ctry_cd, :zipcd, :seq_no) }
  scope :active, -> { where(use_yn_cd: "Y") }

  private
    def normalize_fields
      self.ctry_cd = ctry_cd.to_s.strip.upcase
      self.zipcd = zipcd.to_s.strip.upcase
      self.seq_no = normalize_seq_no(seq_no)
      self.zipaddr = zipaddr.to_s.strip.presence
      self.sido = sido.to_s.strip.presence
      self.sgng = sgng.to_s.strip.presence
      self.eupdiv = eupdiv.to_s.strip.presence
      self.addr_ri = addr_ri.to_s.strip.presence
      self.iland_san = iland_san.to_s.strip.presence
      self.san_houseno = san_houseno.to_s.strip.presence
      self.apt_bild_nm = apt_bild_nm.to_s.strip.presence
      self.strt_houseno_wek = strt_houseno_wek.to_s.strip.presence
      self.strt_houseno_mnst = strt_houseno_mnst.to_s.strip.presence
      self.end_houseno_wek = end_houseno_wek.to_s.strip.presence
      self.end_houseno_mnst = end_houseno_mnst.to_s.strip.presence
      self.dong_rng_strt = dong_rng_strt.to_s.strip.presence
      self.dong_houseno_end = dong_houseno_end.to_s.strip.presence
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

    def normalize_seq_no(value)
      normalized = value.to_s.strip
      if normalized.present? && normalized.match?(/\A\d+\z/)
        normalized.to_i
      else
        nil
      end
    end
end
