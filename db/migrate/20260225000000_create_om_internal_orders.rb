class CreateOmInternalOrders < ActiveRecord::Migration[8.1]
  def up
    unless table_exists?(:om_internal_orders)
      create_table :om_internal_orders do |t|
        t.string :ord_no, limit: 30, null: false
        t.string :ord_stat_cd, limit: 20, null: false, default: "WAIT"
        t.string :ctrt_no, limit: 30
        t.string :ord_type_cd, limit: 20
        t.string :bilg_cust_cd, limit: 20
        t.string :ctrt_cust_cd, limit: 20
        t.string :ord_exec_dept_cd, limit: 20
        t.string :ord_exec_dept_nm, limit: 100
        t.string :ord_exec_ofcr_cd, limit: 20
        t.string :ord_exec_ofcr_nm, limit: 100
        t.string :ord_reason_cd, limit: 20
        t.text :remk

        # 출도착지
        t.string :dpt_type_cd, limit: 20
        t.string :dpt_cd, limit: 30
        t.string :dpt_zip_cd, limit: 10
        t.string :dpt_addr, limit: 200
        t.string :strt_req_ymd, limit: 8
        t.string :arv_type_cd, limit: 20
        t.string :arv_cd, limit: 30
        t.string :arv_zip_cd, limit: 10
        t.string :arv_addr, limit: 200
        t.string :aptd_req_dtm, limit: 14

        t.string :wait_ord_internal_yn, limit: 1, null: false, default: "N"
        t.string :cancel_yn, limit: 1, null: false, default: "N"

        # 감사 필드
        t.string :create_by, limit: 50
        t.datetime :create_time
        t.string :update_by, limit: 50
        t.datetime :update_time
      end

      add_index :om_internal_orders, :ord_no, unique: true
      add_index :om_internal_orders, :ord_stat_cd
      add_index :om_internal_orders, :wait_ord_internal_yn
      add_index :om_internal_orders, :cancel_yn
    end

    unless table_exists?(:om_internal_order_items)
      create_table :om_internal_order_items do |t|
        t.references :internal_order, null: false, foreign_key: { to_table: :om_internal_orders }
        t.integer :seq_no, null: false
        t.string :item_cd, limit: 30, null: false
        t.string :item_nm, limit: 100
        t.string :basis_unit_cd, limit: 20
        t.decimal :ord_qty, precision: 18, scale: 4, default: 0
        t.string :qty_unit_cd, limit: 20
        t.decimal :ord_wgt, precision: 18, scale: 4, default: 0
        t.string :wgt_unit_cd, limit: 20
        t.decimal :ord_vol, precision: 18, scale: 4, default: 0
        t.string :vol_unit_cd, limit: 20

        # 감사 필드
        t.string :create_by, limit: 50
        t.datetime :create_time
        t.string :update_by, limit: 50
        t.datetime :update_time
      end

      add_index :om_internal_order_items, [ :internal_order_id, :seq_no ], unique: true,
        name: "idx_om_internal_order_items_on_order_seq"
    end
  end

  def down
    drop_table :om_internal_order_items if table_exists?(:om_internal_order_items)
    drop_table :om_internal_orders if table_exists?(:om_internal_orders)
  end
end
