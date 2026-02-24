class OmPreOrderUploadBatch < ApplicationRecord
  include Std::Auditable

  self.table_name = "om_pre_order_upload_batches"

  validates :upload_batch_no, presence: true, length: { maximum: 40 }, uniqueness: true
  validates :file_nm, length: { maximum: 255 }, allow_blank: true
  validates :upload_stat_cd, length: { maximum: 30 }, allow_blank: true
  validates :error_cnt, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :use_yn, inclusion: { in: %w[Y N] }

  before_validation :normalize_fields

  scope :active, -> { where(use_yn: "Y") }
  scope :ordered_recent, -> { order(update_time: :desc, create_time: :desc, upload_batch_no: :desc) }

  private
    def normalize_fields
      self.upload_batch_no = upload_batch_no.to_s.strip.upcase
      self.file_nm = file_nm.to_s.strip.presence
      self.upload_stat_cd = upload_stat_cd.to_s.strip.upcase.presence
      self.cust_cd = cust_cd.to_s.strip.upcase.presence
      self.cust_nm = cust_nm.to_s.strip.presence
      self.error_cnt = error_cnt.to_i
      self.use_yn = normalize_yn(use_yn, default_value: "Y")
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
