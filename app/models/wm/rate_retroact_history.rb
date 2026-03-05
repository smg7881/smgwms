class Wm::RateRetroactHistory < ApplicationRecord
  self.table_name = "wm_rate_retroact_histories"

  validates :exce_rslt_no, presence: true, uniqueness: true
  validates :prcs_sctn_cd, inclusion: { in: %w[C U] }

  before_validation :normalize_fields
  before_save :assign_update_audit_fields
  before_create :assign_create_audit_fields

  scope :ordered, -> { order(rslt_std_ymd: :desc, op_rslt_mngt_no: :desc, op_rslt_mngt_no_seq: :desc) }

  private
    def normalize_fields
      self.exce_rslt_no = exce_rslt_no.to_s.strip.presence
      self.op_rslt_mngt_no = op_rslt_mngt_no.to_s.strip.presence
      self.op_rslt_mngt_no_seq = op_rslt_mngt_no_seq.to_i
      self.work_pl_cd = work_pl_cd.to_s.strip.upcase.presence
      self.sell_buy_sctn_cd = sell_buy_sctn_cd.to_s.strip.upcase.presence
      self.bzac_cd = bzac_cd.to_s.strip.upcase.presence
      self.sell_buy_attr_cd = sell_buy_attr_cd.to_s.strip.upcase.presence
      self.cur_cd = cur_cd.to_s.strip.upcase.presence || "KRW"
      self.rtac_proc_stat_cd = rtac_proc_stat_cd.to_s.strip.upcase.presence || "RTAC"
      self.prcs_sctn_cd = prcs_sctn_cd.to_s.strip.upcase.presence || "C"
      self.ref_fee_rt_no = ref_fee_rt_no.to_s.strip.upcase.presence
      self.ref_fee_rt_lineno = ref_fee_rt_lineno.to_i if ref_fee_rt_lineno.present?
      self.rslt_std_ymd = normalize_ymd(rslt_std_ymd)
    end

    def normalize_ymd(value)
      value.to_s.gsub(/[^0-9]/, "").first(8)
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
