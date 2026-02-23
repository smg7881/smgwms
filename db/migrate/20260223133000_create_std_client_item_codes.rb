class CreateStdClientItemCodes < ActiveRecord::Migration[8.1]
  def change
    create_table :std_client_item_codes do |t|
      t.string :item_cd, limit: 20, null: false
      t.string :item_nm, limit: 200, null: false
      t.string :bzac_cd, limit: 20, null: false
      t.string :goodsnm_cd, limit: 20, null: false

      t.string :danger_yn_cd, limit: 1, null: false, default: "N"
      t.string :png_yn_cd, limit: 1, null: false, default: "N"
      t.string :mstair_lading_yn_cd, limit: 1, null: false, default: "N"
      t.string :if_yn_cd, limit: 1, null: false, default: "N"

      t.string :wgt_unit_cd, limit: 20
      t.string :qty_unit_cd, limit: 20
      t.string :tmpt_unit_cd, limit: 20
      t.string :vol_unit_cd, limit: 20
      t.string :basis_unit_cd, limit: 20
      t.string :len_unit_cd, limit: 20

      t.decimal :pckg_qty, precision: 18, scale: 3
      t.decimal :tot_wgt_kg, precision: 18, scale: 3
      t.decimal :net_wgt_kg, precision: 18, scale: 3
      t.decimal :vessel_tmpt_c, precision: 18, scale: 3
      t.decimal :vessel_width_m, precision: 18, scale: 3
      t.decimal :vessel_vert_m, precision: 18, scale: 3
      t.decimal :vessel_hght_m, precision: 18, scale: 3
      t.decimal :vessel_vol_cbm, precision: 18, scale: 3

      t.string :use_yn_cd, limit: 1, null: false, default: "Y"
      t.string :prod_nm_cd, limit: 100, null: false

      t.string :regr_nm_cd, limit: 50, null: false
      t.datetime :reg_date, null: false
      t.string :mdfr_nm_cd, limit: 50, null: false
      t.datetime :chgdt, null: false

      t.string :create_by, limit: 50
      t.datetime :create_time
      t.string :update_by, limit: 50
      t.datetime :update_time
    end

    add_index :std_client_item_codes, [ :bzac_cd, :item_cd ], unique: true
    add_index :std_client_item_codes, :goodsnm_cd
    add_index :std_client_item_codes, :use_yn_cd
  end
end
