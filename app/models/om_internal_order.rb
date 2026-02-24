class OmInternalOrder < ApplicationRecord
  include Std::Auditable

  self.table_name = "om_internal_orders"

  has_many :items, class_name: "OmInternalOrderItem",
    foreign_key: :internal_order_id,
    inverse_of: :internal_order,
    dependent: :destroy
  accepts_nested_attributes_for :items, allow_destroy: true

  validates :ord_no, presence: true, uniqueness: true, length: { maximum: 30 }
  validates :ord_stat_cd, presence: true, length: { maximum: 20 }
  validates :wait_ord_internal_yn, inclusion: { in: %w[Y N] }
  validates :cancel_yn, inclusion: { in: %w[Y N] }
  validate :validate_items_count

  before_validation :assign_ord_no, on: :create

  default_scope { where(wait_ord_internal_yn: "N") }

  scope :by_ord_no, ->(ord_no) { where(ord_no: ord_no.to_s.strip) }

  def cancel!
    self.cancel_yn = "Y"
    self.ord_stat_cd = "CANCEL"
    save!
  end

  private
    def assign_ord_no
      if ord_no.blank?
        self.ord_no = generate_ord_no
      end
    end

    def generate_ord_no
      date_part = Time.current.strftime("%Y%m%d")
      prefix = "IO#{date_part}"

      last_order = OmInternalOrder.unscoped
        .where("ord_no LIKE ?", "#{prefix}%")
        .order(ord_no: :desc)
        .pick(:ord_no)

      if last_order.present?
        last_seq = last_order[-6..].to_i
        next_seq = last_seq + 1
      else
        next_seq = 1
      end

      "#{prefix}#{next_seq.to_s.rjust(6, '0')}"
    end

    def validate_items_count
      if items.size > 20
        errors.add(:items, "은 최대 20건까지 등록 가능합니다.")
      end
    end
end
