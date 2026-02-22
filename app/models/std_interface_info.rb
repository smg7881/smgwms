class StdInterfaceInfo < ApplicationRecord
  include Std::Auditable

  self.table_name = "std_interface_infos"

  validates :corp_cd, presence: true, length: { maximum: 20 }
  validates :if_cd, presence: true, uniqueness: true, length: { maximum: 11 }
  validates :if_meth_cd, presence: true, length: { maximum: 30 }
  validates :if_sctn_cd, presence: true, length: { maximum: 30 }
  validates :if_nm_cd, presence: true, length: { maximum: 150 }
  validates :use_yn_cd, inclusion: { in: %w[Y N] }

  validate :validate_sctn_requirements

  before_validation :assign_if_cd, on: :create
  before_validation :normalize_fields

  scope :ordered, -> { order(:corp_cd, :if_cd) }

  private
    def assign_if_cd
      if if_cd.to_s.strip.present?
        return
      end

      max_num = self.class.where("if_cd LIKE ?", "V%")
                          .pluck(:if_cd)
                          .filter_map do |code|
        raw = code.to_s.strip
        if raw.match?(/\AV\d{10}\z/)
          raw[1..].to_i
        end
      end.max.to_i
      self.if_cd = format("V%010d", max_num + 1)
    end

    def normalize_fields
      self.corp_cd = corp_cd.to_s.strip.upcase
      self.if_cd = if_cd.to_s.strip.upcase
      self.if_meth_cd = if_meth_cd.to_s.strip.upcase
      self.if_sctn_cd = if_sctn_cd.to_s.strip.upcase
      self.if_nm_cd = if_nm_cd.to_s.strip
      self.send_sys_cd = send_sys_cd.to_s.strip.upcase.presence
      self.rcv_sys_cd = rcv_sys_cd.to_s.strip.upcase.presence
      self.rcv_sctn_cd = rcv_sctn_cd.to_s.strip.upcase.presence
      self.use_yn_cd = normalize_yn(use_yn_cd, default_value: "Y")
      self.if_bzac_cd = if_bzac_cd.to_s.strip.upcase.presence
      self.bzac_nm = bzac_nm.to_s.strip.presence
      self.bzac_sys_nm_cd = bzac_sys_nm_cd.to_s.strip.presence
      self.if_desc_cd = if_desc_cd.to_s.strip.presence
    end

    def validate_sctn_requirements
      if if_sctn_cd.to_s.strip.upcase == "INTERNAL"
        if send_sys_cd.blank?
          errors.add(:send_sys_cd, :blank)
        end
        if rcv_sys_cd.blank?
          errors.add(:rcv_sys_cd, :blank)
        end
      else
        if if_bzac_cd.blank?
          errors.add(:if_bzac_cd, :blank)
        end
        if bzac_sys_nm_cd.blank?
          errors.add(:bzac_sys_nm_cd, :blank)
        end
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
