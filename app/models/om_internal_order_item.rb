class OmInternalOrderItem < ApplicationRecord
  include Std::Auditable

  self.table_name = "om_internal_order_items"

  belongs_to :internal_order, class_name: "OmInternalOrder", inverse_of: :items

  validates :seq_no, presence: true
  validates :item_cd, presence: true, length: { maximum: 30 }
  validates :ord_qty, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :ord_wgt, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :ord_vol, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
end
