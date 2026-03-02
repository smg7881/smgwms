require "set"

class AdmMenu < ApplicationRecord
  MAX_LEVEL = 4

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
    tree_ordered_from(ordered.to_a)
  end

  def self.search_tree_with_ancestors(filters)
    scope = ordered
    scope = scope.where("menu_cd LIKE ?", "%#{filters[:menu_cd]}%") if filters[:menu_cd].present?
    scope = scope.where("menu_nm LIKE ?", "%#{filters[:menu_nm]}%") if filters[:menu_nm].present?
    scope = scope.where(use_yn: filters[:use_yn]) if filters[:use_yn].present?

    matched_codes = scope.pluck(:menu_cd)
    return [] if matched_codes.empty?

    all_menus = ordered.to_a
    menus_by_code = all_menus.index_by(&:menu_cd)
    included_codes = Set.new

    matched_codes.each do |menu_cd|
      current = menus_by_code[menu_cd]
      while current
        break if included_codes.include?(current.menu_cd)

        included_codes << current.menu_cd
        current = menus_by_code[current.parent_cd]
      end
    end

    tree_ordered_from(all_menus).select { |menu| included_codes.include?(menu.menu_cd) }
  end

  def self.sidebar_tree
    active.ordered.to_a.group_by(&:parent_cd)
  end

  def self.tree_ordered_from(menus)
    grouped = menus.group_by(&:parent_cd)
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
  private_class_method :tree_ordered_from

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
