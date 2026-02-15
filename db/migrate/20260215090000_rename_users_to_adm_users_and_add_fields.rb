class RenameUsersToAdmUsersAndAddFields < ActiveRecord::Migration[8.1]
  def change
    rename_table :users, :adm_users

    add_column :adm_users, :user_id_code, :string
    add_column :adm_users, :user_nm, :string
    add_column :adm_users, :dept_cd, :string
    add_column :adm_users, :dept_nm, :string
    add_column :adm_users, :role_cd, :string
    add_column :adm_users, :position_cd, :string
    add_column :adm_users, :job_title_cd, :string
    add_column :adm_users, :work_status, :string, default: "ACTIVE"
    add_column :adm_users, :hire_date, :date
    add_column :adm_users, :resign_date, :date
    add_column :adm_users, :phone, :string
    add_column :adm_users, :address, :string
    add_column :adm_users, :detail_address, :string

    add_index :adm_users, :user_id_code, unique: true
    add_index :adm_users, :work_status
  end
end
