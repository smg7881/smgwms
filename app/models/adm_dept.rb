require "set"

class AdmDept < ApplicationRecord
  attr_accessor :dept_level

  validates :dept_code, presence: true, uniqueness: true, length: { maximum: 50 }
  validates :dept_nm, presence: true, length: { maximum: 100 }
  validates :dept_type, length: { maximum: 50 }, allow_blank: true
  validates :parent_dept_code, length: { maximum: 50 }, allow_blank: true
  validates :dept_order, numericality: { only_integer: true }
  validates :use_yn, inclusion: { in: %w[Y N] }

  validate :parent_exists
  validate :prevent_cycle

  before_validation :normalize_fields
  before_save :assign_audit_fields
  before_create :assign_create_fields

  scope :ordered, -> { order(:dept_order, :dept_code) }

  def self.tree_ordered
    grouped = ordered.to_a.group_by(&:parent_dept_code)
    visited = Set.new
    result = []

    walk = lambda do |node, level|
      return if visited.include?(node.dept_code)

      visited << node.dept_code
      node.dept_level = level
      result << node
      children = grouped[node.dept_code] || []
      children.each do |child|
        walk.call(child, level + 1)
      end
    end

    roots = grouped[nil] || []
    roots.each do |root|
      walk.call(root, 1)
    end

    result
  end

  def self.next_child_order(parent_code)
    where(parent_dept_code: parent_code).maximum(:dept_order).to_i + 1
  end

  def children
    AdmDept.where(parent_dept_code: dept_code)
  end

  def calculate_level
    return 1 if parent_dept_code.blank?

    level = 1
    current = parent

    while current
      level += 1
      current = current.parent
    end

    level
  end

  def parent
    return nil if parent_dept_code.blank?

    AdmDept.find_by(dept_code: parent_dept_code)
  end

  private
    def normalize_fields
      self.dept_code = dept_code.to_s.strip.upcase
      self.dept_nm = dept_nm.to_s.strip
      self.parent_dept_code = parent_dept_code.to_s.strip.upcase.presence
      self.dept_type = dept_type.to_s.strip.presence
      self.use_yn = use_yn.to_s.strip.upcase.presence || "Y"

      if dept_order.nil?
        self.dept_order = 0
      end
    end

    def assign_audit_fields
      actor = current_actor
      self.update_by = actor
      self.update_time = Time.current
    end

    def assign_create_fields
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

    def parent_exists
      if parent_dept_code.present? && parent.nil?
        errors.add(:parent_dept_code, "상위 부서를 찾을 수 없습니다.")
      end
    end

    def prevent_cycle
      return if parent_dept_code.blank? || dept_code.blank?

      if parent_dept_code == dept_code
        errors.add(:parent_dept_code, "자기 자신을 상위 부서로 지정할 수 없습니다.")
        return
      end

      ancestor = parent
      while ancestor
        if ancestor.dept_code == dept_code
          errors.add(:parent_dept_code, "순환 구조를 만들 수 없습니다.")
          break
        end
        ancestor = ancestor.parent
      end
    end
end
