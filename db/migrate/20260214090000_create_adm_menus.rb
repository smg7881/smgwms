class CreateAdmMenus < ActiveRecord::Migration[8.1]
  def change
    create_table :adm_menus do |t|
      t.string :menu_cd, limit: 20, null: false
      t.string :menu_nm, limit: 100, null: false
      t.string :parent_cd, limit: 20
      t.string :menu_url, limit: 200
      t.string :menu_icon, limit: 10
      t.integer :sort_order, null: false, default: 0
      t.integer :menu_level, null: false, default: 1
      t.string :menu_type, limit: 10, null: false, default: "MENU"
      t.string :use_yn, limit: 1, null: false, default: "Y"
      t.string :tab_id, limit: 50
      t.timestamps
    end

    add_index :adm_menus, :menu_cd, unique: true
    add_index :adm_menus, :parent_cd
    add_index :adm_menus, [ :parent_cd, :sort_order, :menu_cd ]
  end
end
