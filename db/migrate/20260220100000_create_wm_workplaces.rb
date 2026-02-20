class CreateWmWorkplaces < ActiveRecord::Migration[8.1]
  def change
    create_table :wm_workplaces do |t|
      t.string :workpl_cd, limit: 50, null: false
      t.string :workpl_nm, limit: 100, null: false
      t.string :workpl_type, limit: 50
      t.string :client_cd, limit: 50
      t.string :prop_cd, limit: 50
      t.string :nation_cd, limit: 20
      t.string :zip_cd, limit: 20
      t.string :addr, limit: 300
      t.string :addr_dtl, limit: 300
      t.string :tel_no, limit: 30
      t.string :fax_no, limit: 30
      t.text :remk
      t.string :use_yn, limit: 1, default: "Y", null: false
      t.string :create_by, limit: 50
      t.datetime :create_time
      t.string :update_by, limit: 50
      t.datetime :update_time
    end

    add_index :wm_workplaces, :workpl_cd, unique: true
    add_index :wm_workplaces, :workpl_nm
    add_index :wm_workplaces, :workpl_type
    add_index :wm_workplaces, :use_yn
  end
end
