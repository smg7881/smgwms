class CreateAdmCodeTables < ActiveRecord::Migration[8.1]
  def change
    create_table :adm_code_headers do |t|
      t.string :code, limit: 50, null: false
      t.string :code_name, limit: 100, null: false
      t.string :use_yn, limit: 1, null: false, default: "Y"
      t.string :create_by, limit: 50
      t.datetime :create_time
      t.string :update_by, limit: 50
      t.datetime :update_time
    end

    add_index :adm_code_headers, :code, unique: true
    add_index :adm_code_headers, :use_yn

    create_table :adm_code_details do |t|
      t.string :code, limit: 50, null: false
      t.string :detail_code, limit: 50, null: false
      t.string :detail_code_name, limit: 100, null: false
      t.string :short_name, limit: 100
      t.string :ref_code, limit: 50
      t.integer :sort_order, null: false, default: 0
      t.string :use_yn, limit: 1, null: false, default: "Y"
      t.string :create_by, limit: 50
      t.datetime :create_time
      t.string :update_by, limit: 50
      t.datetime :update_time
    end

    add_index :adm_code_details, [ :code, :detail_code ], unique: true
    add_index :adm_code_details, :code
    add_index :adm_code_details, :use_yn
    add_index :adm_code_details, [ :code, :sort_order, :detail_code ], name: "index_adm_code_details_on_code_order_and_detail_code"
  end
end
