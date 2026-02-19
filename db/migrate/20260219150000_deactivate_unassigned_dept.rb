class DeactivateUnassignedDept < ActiveRecord::Migration[8.1]
  class MigrationDept < ApplicationRecord
    self.table_name = "adm_depts"
  end

  class MigrationUser < ApplicationRecord
    self.table_name = "adm_users"
  end

  def up
    return unless table_exists?(:adm_depts)

    unassigned = MigrationDept.find_by(dept_code: "UNASSIGNED")
    return if unassigned.nil?
    return if table_exists?(:adm_users) && column_exists?(:adm_users, :dept_id) && MigrationUser.where(dept_id: unassigned.id).exists?

    unassigned.update!(use_yn: "N")
  end

  def down
    return unless table_exists?(:adm_depts)

    unassigned = MigrationDept.find_by(dept_code: "UNASSIGNED")
    return if unassigned.nil?

    unassigned.update!(use_yn: "Y")
  end
end
