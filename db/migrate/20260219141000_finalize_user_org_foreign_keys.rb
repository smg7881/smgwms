class FinalizeUserOrgForeignKeys < ActiveRecord::Migration[8.1]
  class MigrationUser < ApplicationRecord
    self.table_name = "adm_users"
  end

  class MigrationRole < ApplicationRecord
    self.table_name = "adm_roles"
  end

  class MigrationDept < ApplicationRecord
    self.table_name = "adm_depts"
  end

  def up
    return unless table_exists?(:adm_users)

    ensure_missing_roles_from_users!
    ensure_missing_depts_from_users!
    backfill_role_id!
    backfill_dept_id!

    remove_column :adm_users, :role_cd, :string if column_exists?(:adm_users, :role_cd)
    remove_column :adm_users, :dept_cd, :string if column_exists?(:adm_users, :dept_cd)
  end

  def down
    return unless table_exists?(:adm_users)

    add_column :adm_users, :role_cd, :string unless column_exists?(:adm_users, :role_cd)
    add_column :adm_users, :dept_cd, :string unless column_exists?(:adm_users, :dept_cd)

    execute <<~SQL
      UPDATE adm_users
      SET role_cd = (
        SELECT adm_roles.role_cd
        FROM adm_roles
        WHERE adm_roles.id = adm_users.role_id
      )
    SQL

    execute <<~SQL
      UPDATE adm_users
      SET dept_cd = (
        SELECT adm_depts.dept_code
        FROM adm_depts
        WHERE adm_depts.id = adm_users.dept_id
      )
    SQL
  end

  private
    def ensure_missing_roles_from_users!
      return unless column_exists?(:adm_users, :role_cd)

      used_codes = MigrationUser.distinct.pluck(:role_cd).map { |code| code.to_s.strip.upcase }.reject(&:blank?)
      existing_codes = MigrationRole.pluck(:role_cd).map { |code| code.to_s.strip.upcase }

      (used_codes - existing_codes).each do |missing_code|
        MigrationRole.create!(
          role_cd: missing_code,
          role_nm: missing_code,
          use_yn: "Y"
        )
      end
    end

    def ensure_missing_depts_from_users!
      return unless column_exists?(:adm_users, :dept_cd)

      used_codes = MigrationUser.distinct.pluck(:dept_cd).map { |code| code.to_s.strip.upcase }.reject(&:blank?)
      existing_codes = MigrationDept.pluck(:dept_code).map { |code| code.to_s.strip.upcase }

      (used_codes - existing_codes).each do |missing_code|
        sample_name = MigrationUser.where("UPPER(COALESCE(dept_cd, '')) = ?", missing_code)
                                  .where.not(dept_nm: [ nil, "" ])
                                  .limit(1)
                                  .pluck(:dept_nm).first

        MigrationDept.create!(
          dept_code: missing_code,
          dept_nm: sample_name.presence || missing_code,
          dept_order: MigrationDept.where(parent_dept_code: nil).maximum(:dept_order).to_i + 1,
          use_yn: "Y"
        )
      end
    end

    def backfill_role_id!
      return unless column_exists?(:adm_users, :role_cd)
      return unless column_exists?(:adm_users, :role_id)

      role_id_by_code = MigrationRole.pluck(:role_cd, :id).to_h
      MigrationUser.find_each do |user|
        code = user[:role_cd].to_s.strip.upcase
        next if code.blank?

        mapped_id = role_id_by_code[code]
        next if mapped_id.nil?

        user.update_columns(role_id: mapped_id)
      end
    end

    def backfill_dept_id!
      return unless column_exists?(:adm_users, :dept_cd)
      return unless column_exists?(:adm_users, :dept_id)

      dept_id_by_code = MigrationDept.pluck(:dept_code, :id).to_h
      MigrationUser.find_each do |user|
        code = user[:dept_cd].to_s.strip.upcase
        next if code.blank?

        mapped_id = dept_id_by_code[code]
        next if mapped_id.nil?

        user.update_columns(dept_id: mapped_id)
      end
    end
end
