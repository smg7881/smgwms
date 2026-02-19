class BackfillMissingUserDeptIds < ActiveRecord::Migration[8.1]
  class MigrationUser < ApplicationRecord
    self.table_name = "adm_users"
  end

  class MigrationDept < ApplicationRecord
    self.table_name = "adm_depts"
  end

  def up
    return unless table_exists?(:adm_users)
    return unless column_exists?(:adm_users, :dept_id)

    fallback_dept = ensure_fallback_dept!

    MigrationUser.where(dept_id: nil).find_each do |user|
      target_dept = find_dept_by_name(user[:dept_nm]) || fallback_dept
      next if target_dept.nil?

      user.update_columns(dept_id: target_dept.id)
    end
  end

  def down
    # no-op: data correction migration
  end

  private
    def ensure_fallback_dept!
      existing = MigrationDept.find_by(dept_code: "UNASSIGNED")
      return existing if existing.present?

      MigrationDept.create!(
        dept_code: "UNASSIGNED",
        dept_nm: "미지정부서",
        dept_order: MigrationDept.where(parent_dept_code: nil).maximum(:dept_order).to_i + 1,
        use_yn: "Y"
      )
    end

    def find_dept_by_name(dept_name)
      normalized = dept_name.to_s.strip
      return nil if normalized.blank?

      MigrationDept.find_by(dept_nm: normalized)
    end
end
