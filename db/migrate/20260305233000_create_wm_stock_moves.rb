class CreateWmStockMoves < ActiveRecord::Migration[8.1]
  def change
    create_table :wm_stock_moves do |t|
      t.string :corp_cd, limit: 10, null: false
      t.string :workpl_cd, limit: 20, null: false
      t.string :cust_cd, limit: 20, null: false
      t.string :item_cd, limit: 30, null: false
      t.string :stock_attr_no, limit: 10, null: false
      t.string :from_loc_cd, limit: 20, null: false
      t.string :to_loc_cd, limit: 20, null: false
      t.decimal :move_qty, precision: 18, scale: 3, null: false, default: 0
      t.string :basis_unit_cls, limit: 10
      t.string :basis_unit_cd, limit: 10
      t.string :move_type, limit: 2, null: false, default: "MV"
      t.string :move_ymd, limit: 8, null: false
      t.string :move_hms, limit: 6, null: false
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
      t.string :create_by, limit: 50
      t.datetime :create_time
      t.string :update_by, limit: 50
      t.datetime :update_time
    end

    add_index :wm_stock_moves, [ :workpl_cd, :move_ymd ], name: "idx_wm_stock_moves_workpl_ymd"
    add_index :wm_stock_moves, [ :corp_cd, :workpl_cd, :stock_attr_no ], name: "idx_wm_stock_moves_stock_attr"
    add_index :wm_stock_moves, [ :from_loc_cd, :to_loc_cd ], name: "idx_wm_stock_moves_from_to_loc"
  end
end
