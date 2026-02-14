require "set"

class AdmMenu < ApplicationRecord
  MAX_LEVEL = 3

  validates :menu_cd, presence: true, uniqueness: true, length: { maximum: 20 }
  validates :menu_nm, presence: true, length: { maximum: 100 }
  validates :menu_type, inclusion: { in: %w[FOLDER MENU] }
  validates :use_yn, inclusion: { in: %w[Y N] }
  validates :menu_level, inclusion: { in: 1..MAX_LEVEL }
  validates :sort_order, numericality: { only_integer: true }

  validate :parent_exists
  validate :level_consistency
  validate :prevent_cycle
  validate :url_required_for_menu

  scope :active, -> { where(use_yn: "Y") }
  scope :ordered, -> { order(:sort_order, :menu_cd) }
  scope :top_level, -> { where(parent_cd: nil) }

  def children
    AdmMenu.where(parent_cd: menu_cd)
  end

  def parent
    return nil if parent_cd.blank?

    AdmMenu.find_by(menu_cd: parent_cd)
  end

  def folder?
    menu_type == "FOLDER"
  end

  def self.tree_ordered
    grouped = ordered.to_a.group_by(&:parent_cd)
    visited = Set.new
    result = []

    walk = lambda do |node|
      return if visited.include?(node.menu_cd)

      visited << node.menu_cd
      result << node
      (grouped[node.menu_cd] || []).each { |child| walk.call(child) }
    end

    (grouped[nil] || []).each { |root| walk.call(root) }
    result
  end

  def self.sidebar_tree
    active.ordered.to_a.group_by(&:parent_cd)
  end

  private
    def parent_exists
      return if parent_cd.blank?

      errors.add(:parent_cd, "상위 메뉴를 찾을 수 없습니다.") if parent.nil?
    end

    def level_consistency
      if parent_cd.blank?
        errors.add(:menu_level, "최상위 메뉴는 1이어야 합니다.") unless menu_level == 1
        return
      end

      return if parent.nil?

      expected = parent.menu_level + 1
      if menu_level != expected
        errors.add(:menu_level, "부모 레벨 기준 #{expected}이어야 합니다.")
      end
    end

    def prevent_cycle
      return if parent_cd.blank? || menu_cd.blank?

      if parent_cd == menu_cd
        errors.add(:parent_cd, "자기 자신을 부모로 지정할 수 없습니다.")
        return
      end

      ancestor = parent
      while ancestor
        if ancestor.menu_cd == menu_cd
          errors.add(:parent_cd, "순환 참조를 만들 수 없습니다.")
          break
        end
        ancestor = ancestor.parent
      end
    end

    def url_required_for_menu
      return unless menu_type == "MENU"
      return if menu_url.present?

      errors.add(:menu_url, "메뉴 타입이 MENU일 때는 필수입니다.")
    end
end
