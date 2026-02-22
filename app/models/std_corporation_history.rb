class StdCorporationHistory < ApplicationRecord
  include Std::Auditable

  self.table_name = "std_corporation_histories"

  validates :corp_cd, presence: true, length: { maximum: 20 }
  validates :hist_seq, presence: true, numericality: { only_integer: true, greater_than: 0 }, uniqueness: { scope: :corp_cd }
  validates :source_kind, presence: true, length: { maximum: 20 }
  validates :changed_col_nm, presence: true, length: { maximum: 120 }

  before_validation :normalize_fields

  scope :ordered, -> { order(:corp_cd, :hist_seq) }

  class << self
    def next_hist_seq_for(corp_cd)
      normalized = corp_cd.to_s.strip.upcase
      if normalized.blank?
        return 1
      end

      where(corp_cd: normalized).maximum(:hist_seq).to_i + 1
    end
  end

  private
    def normalize_fields
      self.corp_cd = corp_cd.to_s.strip.upcase
      self.source_kind = source_kind.to_s.strip.upcase
      self.source_key = source_key.to_s.strip.presence
      self.changed_col_nm = changed_col_nm.to_s.strip
      self.changed_by = changed_by.to_s.strip.presence
    end
end
