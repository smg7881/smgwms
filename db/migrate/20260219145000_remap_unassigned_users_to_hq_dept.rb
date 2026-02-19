class RemapUnassignedUsersToHqDept < ActiveRecord::Migration[8.1]
  class MigrationUser < ApplicationRecord
    self.table_name = "adm_users"
  end

  class MigrationDept < ApplicationRecord
    self.table_name = "adm_depts"
  end

  def up
    return unless table_exists?(:adm_users)
    return unless table_exists?(:adm_depts)
    return unless column_exists?(:adm_users, :dept_id)

    unassigned = MigrationDept.find_by(dept_code: "UNASSIGNED")
    return if unassigned.nil?

    hq = ensure_hq_dept!
    MigrationUser.where(dept_id: unassigned.id).update_all(dept_id: hq.id, dept_nm: hq.dept_nm)
  end

  def down
    # no-op: data correction migration
  end

  private
    def ensure_hq_dept!
      existing = MigrationDept.find_by(dept_code: "HQ")
      return existing if existing.present?

      MigrationDept.create!(
        dept_code: "HQ",
        dept_nm: "본사",
        dept_order: MigrationDept.where(parent_dept_code: nil).maximum(:dept_order).to_i + 1,
        use_yn: "Y"
      )
    end
end
