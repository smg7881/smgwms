class OmOrder < ApplicationRecord
  include Std::Auditable

  self.table_name = "om_orders"

  MANUAL_COMPLETION_TARGET_STATUS_CODES = %w[50 WORKING IN_PROGRESS].freeze
  MANUAL_COMPLETION_DONE_STATUS_CODE = "60".freeze
  MANUAL_COMPLETION_DIVISION_CODE = "20".freeze
  MANUAL_COMPLETION_EXCLUDED_TYPE_CODE = "30".freeze

  validates :ord_no, presence: true, length: { maximum: 30 }, uniqueness: true
  validates :use_yn, inclusion: { in: %w[Y N] }

  before_validation :normalize_fields

  scope :active, -> { where(use_yn: "Y") }
  scope :ordered_recent, -> { order(update_time: :desc, create_time: :desc, ord_no: :desc) }
  scope :manual_completion_candidates, lambda {
    active
      .where(ord_stat_cd: MANUAL_COMPLETION_TARGET_STATUS_CODES)
      .where.not(ord_type_cd: MANUAL_COMPLETION_EXCLUDED_TYPE_CODE)
  }

  def manual_completable?
    if use_yn != "Y"
      return false
    end

    if ord_type_cd == MANUAL_COMPLETION_EXCLUDED_TYPE_CODE
      return false
    end

    MANUAL_COMPLETION_TARGET_STATUS_CODES.include?(ord_stat_cd)
  end

  def manual_complete!(reason:)
    update!(
      ord_stat_cd: MANUAL_COMPLETION_DONE_STATUS_CODE,
      ord_cmpt_div_cd: MANUAL_COMPLETION_DIVISION_CODE,
      ord_cmpt_dtm: Time.current,
      manl_cmpt_rsn: reason.to_s.strip.presence
    )
  end

  private
    def normalize_fields
      self.ord_no = ord_no.to_s.strip.upcase
      self.cust_cd = cust_cd.to_s.strip.upcase.presence
      self.cust_nm = cust_nm.to_s.strip.presence
      self.cust_ord_no = cust_ord_no.to_s.strip.upcase.presence
      self.item_cd = item_cd.to_s.strip.upcase.presence
      self.item_nm = item_nm.to_s.strip.presence
      self.ord_stat_cd = ord_stat_cd.to_s.strip.upcase.presence
      self.ord_type_cd = ord_type_cd.to_s.strip.upcase.presence
      self.ord_type_nm = ord_type_nm.to_s.strip.presence
      self.ord_cmpt_div_cd = ord_cmpt_div_cd.to_s.strip.upcase.presence
      self.manl_cmpt_rsn = manl_cmpt_rsn.to_s.strip.presence
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
