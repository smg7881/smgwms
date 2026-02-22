class StdUserFavoriteGroup < ApplicationRecord
  include Std::Auditable

  self.table_name = "std_user_favorite_groups"

  validates :user_id_code, presence: true, length: { maximum: 16 }
  validates :group_nm, presence: true, length: { maximum: 100 }, uniqueness: { scope: :user_id_code }
  validates :use_yn, inclusion: { in: %w[Y N] }

  before_validation :normalize_fields

  scope :ordered, -> { order(:user_id_code, :group_nm) }
  scope :active, -> { where(use_yn: "Y") }

  private
    def normalize_fields
      self.user_id_code = user_id_code.to_s.strip.upcase
      self.group_nm = group_nm.to_s.strip
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
