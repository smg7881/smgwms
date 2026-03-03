class StdUserFavorite < ApplicationRecord
  include Std::Auditable

  self.table_name = "std_user_favorites"

  validates :user_id_code, presence: true, length: { maximum: 16 }
  validates :menu_cd, presence: true, length: { maximum: 20 }, uniqueness: { scope: :user_id_code }
  validates :user_favor_menu_grp, length: { maximum: 100 }, allow_blank: true
  validates :sort_seq, numericality: { only_integer: true }
  validates :use_yn, inclusion: { in: %w[Y N] }

  before_validation :normalize_fields
  before_validation :fill_menu_name

  scope :ordered, -> { order(:user_id_code, :sort_seq, :menu_cd) }
  scope :active, -> { where(use_yn: "Y") }

  private
    def normalize_fields
      self.user_id_code = user_id_code.to_s.strip.upcase
      self.menu_cd = menu_cd.to_s.strip.upcase
      self.menu_nm = menu_nm.to_s.strip.presence
      self.user_favor_menu_grp = user_favor_menu_grp.to_s.strip.presence
      self.sort_seq = sort_seq.to_i
      self.use_yn = normalize_yn(use_yn, default_value: "Y")
    end

    def fill_menu_name
      if menu_cd.blank?
        return
      end
      if menu_nm.present?
        return
      end

      menu = AdmMenu.find_by(menu_cd: menu_cd)
      self.menu_nm = menu&.menu_nm
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
