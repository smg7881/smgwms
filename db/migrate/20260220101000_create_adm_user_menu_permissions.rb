class CreateAdmUserMenuPermissions < ActiveRecord::Migration[8.1]
  def change
    create_table :adm_user_menu_permissions do |t|
      t.references :user, null: false, foreign_key: { to_table: :adm_users }
      t.string :menu_cd, limit: 20, null: false
      t.string :use_yn, limit: 1, default: "Y", null: false
      t.string :create_by, limit: 50
      t.datetime :create_time
      t.string :update_by, limit: 50
      t.datetime :update_time
    end

    add_index :adm_user_menu_permissions, [ :user_id, :menu_cd ], unique: true, name: "index_user_menu_permissions_on_user_and_menu"
    add_index :adm_user_menu_permissions, :menu_cd
    add_index :adm_user_menu_permissions, :use_yn
  end
end
