class StdGood < ApplicationRecord
  include Std::Auditable

  self.table_name = "std_goods"

  validates :goods_cd, presence: true, uniqueness: true, length: { maximum: 20 }
  validates :goods_nm, presence: true, length: { maximum: 200 }
  validates :use_yn_cd, inclusion: { in: %w[Y N] }

  before_validation :assign_goods_cd, on: :create
  before_validation :normalize_fields

  scope :ordered, -> { order(:goods_cd) }

  private
    def assign_goods_cd
      if goods_cd.to_s.strip.present?
        return
      end

      numeric_codes = self.class.pluck(:goods_cd).filter_map do |code|
        stripped = code.to_s.strip
        if stripped.match?(/\A\d+\z/)
          stripped.to_i
        end
      end
      self.goods_cd = format("%08d", numeric_codes.max.to_i + 1)
    end

    def normalize_fields
      self.goods_cd = goods_cd.to_s.strip.upcase
      self.goods_nm = goods_nm.to_s.strip
      self.hatae_cd = hatae_cd.to_s.strip.upcase.presence
      self.item_grp_cd = item_grp_cd.to_s.strip.upcase.presence
      self.item_cd = item_cd.to_s.strip.upcase.presence
      self.hwajong_cd = hwajong_cd.to_s.strip.upcase.presence
      self.hwajong_grp_cd = hwajong_grp_cd.to_s.strip.upcase.presence
      self.rmk_cd = rmk_cd.to_s.strip.presence
      self.use_yn_cd = normalize_yn(use_yn_cd, default_value: "Y")
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
