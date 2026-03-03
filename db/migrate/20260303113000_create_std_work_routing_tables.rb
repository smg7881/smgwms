class CreateStdWorkRoutingTables < ActiveRecord::Migration[8.1]
  def change
    create_table :std_work_routings do |t|
      t.string :wrk_rt_cd, limit: 20, null: false
      t.string :wrk_rt_nm, limit: 150, null: false
      t.string :hwajong_cd, limit: 30
      t.string :wrk_type1_cd, limit: 30
      t.string :wrk_type2_cd, limit: 30
      t.string :use_yn_cd, limit: 1, null: false, default: "Y"
      t.string :rmk_cd, limit: 500
      t.string :create_by, limit: 50
      t.datetime :create_time
      t.string :update_by, limit: 50
      t.datetime :update_time
    end

    add_index :std_work_routings, :wrk_rt_cd, unique: true
    add_index :std_work_routings, :wrk_rt_nm
    add_index :std_work_routings, :use_yn_cd

    create_table :std_work_routing_steps do |t|
      t.string :wrk_rt_cd, limit: 20, null: false
      t.integer :seq_no, null: false
      t.string :work_step_cd, limit: 30, null: false
      t.string :work_step_level1_cd, limit: 30
      t.string :work_step_level2_cd, limit: 30
      t.string :use_yn_cd, limit: 1, null: false, default: "Y"
      t.string :rmk_cd, limit: 500
      t.string :create_by, limit: 50
      t.datetime :create_time
      t.string :update_by, limit: 50
      t.datetime :update_time
    end

    add_index :std_work_routing_steps, [ :wrk_rt_cd, :seq_no ], unique: true
    add_index :std_work_routing_steps, :wrk_rt_cd
    add_index :std_work_routing_steps, :use_yn_cd
  end
end
