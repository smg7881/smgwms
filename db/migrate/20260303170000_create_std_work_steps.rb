class CreateStdWorkSteps < ActiveRecord::Migration[8.1]
  def change
    create_table :std_work_steps do |t|
      t.string :work_step_cd, limit: 30, null: false
      t.string :work_step_nm, limit: 150, null: false
      t.string :work_step_level1_cd, limit: 30, null: false
      t.string :work_step_level2_cd, limit: 30, null: false
      t.integer :sort_seq, null: false, default: 0
      t.text :conts_cd
      t.string :rmk_cd, limit: 500
      t.string :use_yn_cd, limit: 1, null: false, default: "Y"
      t.string :create_by, limit: 50
      t.datetime :create_time
      t.string :update_by, limit: 50
      t.datetime :update_time
    end

    add_index :std_work_steps, :work_step_cd, unique: true
    add_index :std_work_steps, :work_step_nm
    add_index :std_work_steps, :work_step_level1_cd
    add_index :std_work_steps, :work_step_level2_cd
    add_index :std_work_steps, :use_yn_cd
  end
end
