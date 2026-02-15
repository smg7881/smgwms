class CreateAdmDepts < ActiveRecord::Migration[8.1]
  def change
    create_table :adm_depts, id: false do |t|
      t.string :dept_code, limit: 50, null: false
      t.string :dept_nm, limit: 100, null: false
      t.string :dept_type, limit: 50
      t.string :parent_dept_code, limit: 50
      t.text :description
      t.integer :dept_order, null: false, default: 0
      t.string :use_yn, limit: 1, null: false, default: "Y"
      t.string :create_by, limit: 50
      t.datetime :create_time
      t.string :update_by, limit: 50
      t.datetime :update_time
    end

    add_index :adm_depts, :dept_code, unique: true
    add_index :adm_depts, :parent_dept_code
    add_index :adm_depts, [ :parent_dept_code, :dept_order, :dept_code ], name: "index_adm_depts_on_parent_order_and_code"
    add_index :adm_depts, :use_yn
  end
end
