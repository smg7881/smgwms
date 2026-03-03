class OmPreOrderError < ApplicationRecord
  include Std::Auditable

  self.table_name = "om_pre_order_errors"

  validates :upload_batch_no, presence: true, length: { maximum: 40 }
  validates :line_no, presence: true, numericality: { greater_than_or_equal_to: 1, only_integer: true }
  validates :err_type_cd, length: { maximum: 30 }, allow_blank: true
  validates :err_msg, length: { maximum: 500 }, allow_blank: true
  validates :cust_ord_no, length: { maximum: 40 }, allow_blank: true
  validates :item_cd, length: { maximum: 40 }, allow_blank: true
  validates :resolved_yn, inclusion: { in: %w[Y N] }
  validates :use_yn, inclusion: { in: %w[Y N] }
  validates :line_no, uniqueness: { scope: :upload_batch_no }

  before_validation :normalize_fields

  scope :active, -> { where(use_yn: "Y") }

  private
    def normalize_fields
      self.upload_batch_no = upload_batch_no.to_s.strip.upcase
      normalized_line_no = line_no.to_s.strip
      if normalized_line_no.present?
        self.line_no = normalized_line_no.to_i
      else
        self.line_no = nil
      end
      self.err_type_cd = err_type_cd.to_s.strip.upcase.presence
      self.err_msg = err_msg.to_s.strip.presence
      self.cust_ord_no = cust_ord_no.to_s.strip.upcase.presence
      self.item_cd = item_cd.to_s.strip.upcase.presence
      self.resolved_yn = normalize_yn(resolved_yn, default_value: "N")
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
