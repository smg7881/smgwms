class CreateWmCustStockAttrs < ActiveRecord::Migration[8.1]
  def change
    create_table :wm_cust_stock_attrs do |t|
      t.string :cust_cd, limit: 50, null: false
      t.string :inout_sctn, limit: 50, null: false
      t.string :stock_attr_sctn, limit: 50, null: false
      t.string :attr_desc, limit: 500
      t.string :rel_tbl, limit: 50
      t.string :rel_col, limit: 50
      t.string :use_yn, limit: 1, default: "Y", null: false
      t.string :create_by, limit: 50
      t.datetime :create_time
      t.string :update_by, limit: 50
      t.datetime :update_time
    end

    add_index :wm_cust_stock_attrs, [ :cust_cd, :inout_sctn, :stock_attr_sctn ], unique: true, name: 'idx_wm_cust_stock_attrs_uk'
  end
end
