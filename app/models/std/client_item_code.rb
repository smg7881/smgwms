class StdClientItemCode < ApplicationRecord
  include Std::Auditable

  self.table_name = "std_client_item_codes"

  YN_COLUMNS = %i[danger_yn_cd png_yn_cd mstair_lading_yn_cd if_yn_cd use_yn_cd].freeze

  validates :item_cd, presence: true, length: { maximum: 20 }, uniqueness: { scope: :bzac_cd }
  validates :item_nm, presence: true, length: { maximum: 200 }
  validates :bzac_cd, presence: true, length: { maximum: 20 }
  validates :goodsnm_cd, presence: true, length: { maximum: 20 }
  validates :wgt_unit_cd, length: { maximum: 20 }, allow_blank: true
  validates :qty_unit_cd, length: { maximum: 20 }, allow_blank: true
  validates :tmpt_unit_cd, length: { maximum: 20 }, allow_blank: true
  validates :vol_unit_cd, length: { maximum: 20 }, allow_blank: true
  validates :basis_unit_cd, length: { maximum: 20 }, allow_blank: true
  validates :len_unit_cd, length: { maximum: 20 }, allow_blank: true
  validates :prod_nm_cd, presence: true, length: { maximum: 100 }
  validates :regr_nm_cd, presence: true, length: { maximum: 50 }
  validates :mdfr_nm_cd, presence: true, length: { maximum: 50 }
  validates :reg_date, presence: true
  validates :chgdt, presence: true
  validates :pckg_qty, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true
  validates :tot_wgt_kg, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true
  validates :net_wgt_kg, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true
  validates :vessel_width_m, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true
  validates :vessel_vert_m, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true
  validates :vessel_hght_m, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true
  validates :vessel_vol_cbm, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true

  YN_COLUMNS.each do |field|
    validates field, inclusion: { in: %w[Y N] }
  end

  before_validation :normalize_fields
  before_validation :assign_business_audit_fields

  scope :ordered, -> { order(:bzac_cd, :item_cd, :id) }

  private
    def normalize_fields
      self.item_cd = item_cd.to_s.strip.upcase
      self.item_nm = item_nm.to_s.strip
      self.bzac_cd = bzac_cd.to_s.strip.upcase
      self.goodsnm_cd = goodsnm_cd.to_s.strip.upcase

      self.wgt_unit_cd = wgt_unit_cd.to_s.strip.upcase.presence
      self.qty_unit_cd = qty_unit_cd.to_s.strip.upcase.presence
      self.tmpt_unit_cd = tmpt_unit_cd.to_s.strip.upcase.presence
      self.vol_unit_cd = vol_unit_cd.to_s.strip.upcase.presence
      self.basis_unit_cd = basis_unit_cd.to_s.strip.upcase.presence
      self.len_unit_cd = len_unit_cd.to_s.strip.upcase.presence
      self.prod_nm_cd = prod_nm_cd.to_s.strip

      YN_COLUMNS.each do |field|
        default_value = field == :use_yn_cd ? "Y" : "N"
        self[field] = normalize_yn(self[field], default_value: default_value)
      end
    end

    def assign_business_audit_fields
      now = Time.current
      actor = business_actor

      if new_record?
        if regr_nm_cd.to_s.strip.blank?
          self.regr_nm_cd = actor
        end
        self.reg_date = reg_date.presence || now
      end

      self.mdfr_nm_cd = actor
      self.chgdt = now
    end

    def normalize_yn(value, default_value:)
      normalized = value.to_s.strip.upcase
      if normalized.present?
        normalized
      else
        default_value
      end
    end

    def business_actor
      if Current.user&.user_id_code.present?
        Current.user.user_id_code
      elsif Current.user&.email_address.present?
        Current.user.email_address
      else
        "system"
      end
    end
end
