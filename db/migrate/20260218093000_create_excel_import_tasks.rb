class CreateExcelImportTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :excel_import_tasks do |t|
      t.string :resource_key, null: false
      t.string :status, null: false, default: "queued"
      t.integer :total_rows, null: false, default: 0
      t.integer :success_rows, null: false, default: 0
      t.integer :failed_rows, null: false, default: 0
      t.string :source_filename
      t.bigint :source_byte_size
      t.text :error_summary
      t.datetime :started_at
      t.datetime :completed_at
      t.references :requested_by, foreign_key: { to_table: :adm_users }

      t.timestamps
    end

    add_index :excel_import_tasks, [ :resource_key, :created_at ]
    add_index :excel_import_tasks, :status
  end
end
