class BackfillMissingUserRoleIds < ActiveRecord::Migration[8.1]
  class MigrationUser < ApplicationRecord
    self.table_name = "adm_users"
  end

  class MigrationRole < ApplicationRecord
    self.table_name = "adm_roles"
  end

  def up
    return unless table_exists?(:adm_users)
    return unless column_exists?(:adm_users, :role_id)

    admin_role_id = MigrationRole.find_by(role_cd: "ADMIN")&.id
    user_role_id = MigrationRole.find_by(role_cd: "USER")&.id

    MigrationUser.where(role_id: nil).find_each do |user|
      fallback_role_id = if admin_role_id.present? && user[:user_nm].to_s.include?("관리자")
        admin_role_id
      else
        user_role_id
      end

      next if fallback_role_id.nil?

      user.update_columns(role_id: fallback_role_id)
    end
  end

  def down
    # no-op: data correction migration
  end
end
