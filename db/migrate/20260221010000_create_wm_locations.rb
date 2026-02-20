class CreateWmLocations < ActiveRecord::Migration[8.1]
  def change
    create_table :wm_locations do |t|
      t.string :workpl_cd, limit: 50, null: false
      t.string :area_cd, limit: 50, null: false
      t.string :zone_cd, limit: 50, null: false
      t.string :loc_cd, limit: 50, null: false
      t.string :loc_nm, limit: 100, null: false
      t.string :loc_class_cd, limit: 30
      t.string :loc_type_cd, limit: 30
      t.decimal :width_len, precision: 12, scale: 3
      t.decimal :vert_len, precision: 12, scale: 3
      t.decimal :height_len, precision: 12, scale: 3
      t.decimal :max_weight, precision: 14, scale: 3
      t.decimal :max_cbm, precision: 14, scale: 3
      t.string :has_stock, limit: 1, default: "N", null: false
      t.string :use_yn, limit: 1, default: "Y", null: false
      t.string :create_by, limit: 50
      t.datetime :create_time
      t.string :update_by, limit: 50
      t.datetime :update_time
    end

    add_index :wm_locations, [ :workpl_cd, :area_cd, :zone_cd, :loc_cd ], unique: true
    add_index :wm_locations, [ :workpl_cd, :area_cd, :zone_cd ]
    add_index :wm_locations, :loc_nm
    add_index :wm_locations, :use_yn
    add_index :wm_locations, :has_stock
  end
end
