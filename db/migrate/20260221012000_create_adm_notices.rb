class CreateAdmNotices < ActiveRecord::Migration[8.1]
  def change
    create_table :adm_notices do |t|
      t.string :category_code, limit: 50, null: false
      t.string :title, limit: 200, null: false
      t.text :content, null: false
      t.string :is_top_fixed, limit: 1, null: false, default: "N"
      t.string :is_published, limit: 1, null: false, default: "Y"
      t.date :start_date
      t.date :end_date
      t.integer :view_count, null: false, default: 0
      t.string :create_by, limit: 50
      t.datetime :create_time
      t.string :update_by, limit: 50
      t.datetime :update_time
    end

    add_index :adm_notices, :category_code
    add_index :adm_notices, :is_top_fixed
    add_index :adm_notices, :is_published
    add_index :adm_notices, :create_time
  end
end
