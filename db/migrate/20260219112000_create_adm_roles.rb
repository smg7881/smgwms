class CreateAdmRoles < ActiveRecord::Migration[8.1]
  def change
    create_table :adm_roles, id: false do |t|
      t.string :role_cd, limit: 50, null: false
      t.string :role_nm, limit: 100, null: false
      t.text :description
      t.string :use_yn, limit: 1, default: "Y", null: false
      t.string :create_by, limit: 50
      t.datetime :create_time
      t.string :update_by, limit: 50
      t.datetime :update_time
    end

    add_index :adm_roles, :role_cd, unique: true
    add_index :adm_roles, :use_yn
  end
end
