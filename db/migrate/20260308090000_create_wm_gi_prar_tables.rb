class CreateWmGiPrarTables < ActiveRecord::Migration[8.1]
  def change
    create_table :wm_gi_prars, primary_key: :gi_prar_no, id: :string, limit: 20 do |t|
      t.string :workpl_cd, limit: 20, null: false
      t.string :corp_cd, limit: 10, null: false
      t.string :cust_cd, limit: 20, null: false
      t.string :gi_type_cd, limit: 10
      t.string :gi_stat_cd, limit: 10, null: false, default: "10"
      t.string :idct_ymd, limit: 8
      t.string :gi_ymd, limit: 8
      t.string :gi_hms, limit: 6
      t.string :ord_no, limit: 30
      t.string :exec_ord_no, limit: 30
      t.string :asign_no, limit: 30
      t.string :dlv_prar_ymd, limit: 8
      t.string :dlv_prar_hms, limit: 6
      t.string :car_no, limit: 20
      t.string :driver_nm, limit: 50
      t.string :driver_telno, limit: 20
      t.string :transco_cd, limit: 20
      t.string :rmk, limit: 500
      t.string :create_by, limit: 50
      t.datetime :create_time
      t.string :update_by, limit: 50
      t.datetime :update_time
    end

    add_index :wm_gi_prars, :workpl_cd
    add_index :wm_gi_prars, :cust_cd
    add_index :wm_gi_prars, :gi_stat_cd
    add_index :wm_gi_prars, :idct_ymd
    add_index :wm_gi_prars, :gi_ymd

    create_table :wm_gi_prar_details, id: false do |t|
      t.string :gi_prar_no, limit: 20, null: false
      t.integer :lineno, null: false
      t.string :item_cd, limit: 30, null: false
      t.string :item_nm, limit: 200
      t.string :unit_cd, limit: 10
      t.decimal :gi_idct_qty, precision: 18, scale: 3, default: 0
      t.decimal :gi_rslt_qty, precision: 18, scale: 3, default: 0
      t.decimal :assign_qty, precision: 18, scale: 3, default: 0
      t.decimal :pick_qty, precision: 18, scale: 3, default: 0
      t.string :gi_stat_cd, limit: 10, default: "10"
      t.string :stock_attr_col01, limit: 100
      t.string :stock_attr_col02, limit: 100
      t.string :stock_attr_col03, limit: 100
      t.string :stock_attr_col04, limit: 100
      t.string :stock_attr_col05, limit: 100
      t.string :stock_attr_col06, limit: 100
      t.string :stock_attr_col07, limit: 100
      t.string :stock_attr_col08, limit: 100
      t.string :stock_attr_col09, limit: 100
      t.string :stock_attr_col10, limit: 100
      t.string :rmk, limit: 500
      t.string :create_by, limit: 50
      t.datetime :create_time
      t.string :update_by, limit: 50
      t.datetime :update_time
    end

    add_index :wm_gi_prar_details, [ :gi_prar_no, :lineno ], unique: true
    add_index :wm_gi_prar_details, :item_cd
    add_index :wm_gi_prar_details, :gi_stat_cd

    create_table :wm_gi_picks, primary_key: :pick_no, id: :string, limit: 20 do |t|
      t.string :gi_prar_no, limit: 20, null: false
      t.integer :lineno, null: false
      t.string :item_cd, limit: 30, null: false
      t.string :item_nm, limit: 200
      t.string :unit_cd, limit: 10
      t.string :loc_cd, limit: 20
      t.string :stock_attr_no, limit: 10
      t.decimal :stock_qty, precision: 18, scale: 3, default: 0
      t.decimal :assign_qty, precision: 18, scale: 3, default: 0
      t.decimal :pick_qty, precision: 18, scale: 3, default: 0
      t.string :pick_stat_cd, limit: 10, default: "10"
      t.string :pick_ymd, limit: 8
      t.string :pick_hms, limit: 6
      t.string :stock_attr_col01, limit: 100
      t.string :stock_attr_col02, limit: 100
      t.string :stock_attr_col03, limit: 100
      t.string :stock_attr_col04, limit: 100
      t.string :stock_attr_col05, limit: 100
      t.string :stock_attr_col06, limit: 100
      t.string :stock_attr_col07, limit: 100
      t.string :stock_attr_col08, limit: 100
      t.string :stock_attr_col09, limit: 100
      t.string :stock_attr_col10, limit: 100
      t.string :rmk, limit: 500
      t.string :create_by, limit: 50
      t.datetime :create_time
      t.string :update_by, limit: 50
      t.datetime :update_time
    end

    add_index :wm_gi_picks, :gi_prar_no
    add_index :wm_gi_picks, [ :gi_prar_no, :lineno ]
    add_index :wm_gi_picks, [ :gi_prar_no, :item_cd ]
  end
end
