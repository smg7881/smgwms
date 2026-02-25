module Wm
  class CustStockAttr < ApplicationRecord
    self.table_name = "wm_cust_stock_attrs"

    validates :cust_cd, presence: true, length: { maximum: 50 }
    validates :inout_sctn, presence: true, length: { maximum: 50 }
    validates :stock_attr_sctn, presence: true, length: { maximum: 50 }
    validates :use_yn, inclusion: { in: %w[Y N] }
    validates :cust_cd, uniqueness: { scope: [ :inout_sctn, :stock_attr_sctn ] }

    before_validation :normalize_fields
    before_save :assign_update_audit_fields
    before_create :assign_create_audit_fields

    scope :ordered, -> { order(:cust_cd, :inout_sctn, :stock_attr_sctn) }

    private
      def normalize_fields
        self.cust_cd = cust_cd.to_s.strip.upcase
        self.inout_sctn = inout_sctn.to_s.strip
        self.stock_attr_sctn = stock_attr_sctn.to_s.strip
        self.attr_desc = attr_desc.to_s.strip.presence
        self.rel_tbl = rel_tbl.to_s.strip.presence
        self.rel_col = rel_col.to_s.strip.presence
        self.use_yn = use_yn.to_s.strip.upcase.presence || "Y"
      end

      def assign_update_audit_fields
        actor = current_actor
        self.update_by = actor
        self.update_time = Time.current
      end

      def assign_create_audit_fields
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
end
