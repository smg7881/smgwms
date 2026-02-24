class OmPreOrderReception < ApplicationRecord
  include Std::Auditable

  self.table_name = "om_pre_order_receptions"

  STATUS_RECEIVED = "RECEIVED".freeze
  STATUS_ORDER_CREATED = "ORDER_CREATED".freeze
  ORDER_CREATED_STATUSES = [ STATUS_ORDER_CREATED, "CREATED" ].freeze

  validates :bef_ord_no, presence: true, length: { maximum: 30 }, uniqueness: true
  validates :cust_cd, length: { maximum: 20 }, allow_blank: true
  validates :cust_nm, length: { maximum: 120 }, allow_blank: true
  validates :cust_ord_no, length: { maximum: 40 }, allow_blank: true
  validates :item_cd, length: { maximum: 40 }, allow_blank: true
  validates :item_nm, length: { maximum: 150 }, allow_blank: true
  validates :status_cd, length: { maximum: 30 }, allow_blank: true
  validates :use_yn, inclusion: { in: %w[Y N] }

  before_validation :normalize_fields

  scope :active, -> { where(use_yn: "Y") }
  scope :ordered, -> { order(Arel.sql("COALESCE(update_time, create_time) DESC"), :bef_ord_no) }

  def order_created?
    ORDER_CREATED_STATUSES.include?(status_cd.to_s.strip.upcase)
  end

  private
    def normalize_fields
      self.bef_ord_no = bef_ord_no.to_s.strip.upcase
      self.cust_cd = cust_cd.to_s.strip.upcase.presence
      self.cust_nm = cust_nm.to_s.strip.presence
      self.cust_ord_no = cust_ord_no.to_s.strip.upcase.presence
      self.item_cd = item_cd.to_s.strip.upcase.presence
      self.item_nm = item_nm.to_s.strip.presence
      self.status_cd = normalize_status(status_cd)
      self.use_yn = normalize_yn(use_yn, default_value: "Y")
    end

    def normalize_status(value)
      normalized = value.to_s.strip.upcase
      if normalized.present?
        normalized
      else
        STATUS_RECEIVED
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
