class AddDeptIdAndRoleIdToAdmUsers < ActiveRecord::Migration[8.1]
  class MigrationUser < ApplicationRecord
    self.table_name = "adm_users"
  end

  class MigrationDept < ApplicationRecord
    self.table_name = "adm_depts"
  end

  class MigrationRole < ApplicationRecord
    self.table_name = "adm_roles"
  end

  def up
    return unless table_exists?(:adm_users)

    add_reference :adm_users, :dept, null: true, foreign_key: { to_table: :adm_depts }, index: true
    add_reference :adm_users, :role, null: true, foreign_key: { to_table: :adm_roles }, index: true

    backfill_dept_id!
    backfill_role_id!
  end

  def down
    return unless table_exists?(:adm_users)

    remove_reference :adm_users, :dept, foreign_key: { to_table: :adm_depts }, index: true
    remove_reference :adm_users, :role, foreign_key: { to_table: :adm_roles }, index: true
  end

  private
    def backfill_dept_id!
      dept_id_by_code = MigrationDept.pluck(:dept_code, :id).to_h
      MigrationUser.find_each do |user|
        dept_code = user[:dept_cd].to_s.strip.upcase
        next if dept_code.blank?

        mapped_id = dept_id_by_code[dept_code]
        next if mapped_id.nil?

        user.update_columns(dept_id: mapped_id)
      end
    end

    def backfill_role_id!
      role_id_by_code = MigrationRole.pluck(:role_cd, :id).to_h
      MigrationUser.find_each do |user|
        role_code = user[:role_cd].to_s.strip.upcase
        next if role_code.blank?

        mapped_id = role_id_by_code[role_code]
        next if mapped_id.nil?

        user.update_columns(role_id: mapped_id)
      end
    end
end
