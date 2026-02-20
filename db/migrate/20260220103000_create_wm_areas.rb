class CreateWmAreas < ActiveRecord::Migration[8.1]
  def change
    create_table :wm_areas do |t|
      t.string :workpl_cd, limit: 50, null: false
      t.string :area_cd, limit: 50, null: false
      t.string :area_nm, limit: 100, null: false
      t.string :area_desc, limit: 500
      t.string :use_yn, limit: 1, default: "Y", null: false
      t.string :create_by, limit: 50
      t.datetime :create_time
      t.string :update_by, limit: 50
      t.datetime :update_time
    end

    add_index :wm_areas, [ :workpl_cd, :area_cd ], unique: true
    add_index :wm_areas, :workpl_cd
    add_index :wm_areas, :area_nm
    add_index :wm_areas, :use_yn
  end
end
