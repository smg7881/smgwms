class ChangeAdmRolesAndAdmDeptsPrimaryKeyToId < ActiveRecord::Migration[8.1]
  def up
    migrate_adm_roles_to_id_pk
    migrate_adm_depts_to_id_pk
  end

  def down
    rollback_adm_roles_to_code_pk
    rollback_adm_depts_to_code_pk
  end

  private
    def migrate_adm_roles_to_id_pk
      return unless table_exists?(:adm_roles)

      rename_table :adm_roles, :adm_roles_legacy

      create_table :adm_roles do |t|
        t.string :create_by, limit: 50
        t.datetime :create_time
        t.text :description
        t.string :role_cd, limit: 50, null: false
        t.string :role_nm, limit: 100, null: false
        t.string :update_by, limit: 50
        t.datetime :update_time
        t.string :use_yn, limit: 1, default: "Y", null: false
      end

      add_index :adm_roles, :role_cd, unique: true
      add_index :adm_roles, :use_yn

      execute <<~SQL
        INSERT INTO adm_roles (create_by, create_time, description, role_cd, role_nm, update_by, update_time, use_yn)
        SELECT create_by, create_time, description, role_cd, role_nm, update_by, update_time, use_yn
        FROM adm_roles_legacy
      SQL

      drop_table :adm_roles_legacy
    end

    def migrate_adm_depts_to_id_pk
      return unless table_exists?(:adm_depts)

      rename_table :adm_depts, :adm_depts_legacy
      remove_index :adm_depts_legacy, name: "index_adm_depts_on_parent_order_and_code", if_exists: true

      create_table :adm_depts do |t|
        t.string :create_by, limit: 50
        t.datetime :create_time
        t.string :dept_code, limit: 50, null: false
        t.string :dept_nm, limit: 100, null: false
        t.integer :dept_order, default: 0, null: false
        t.string :dept_type, limit: 50
        t.text :description
        t.string :parent_dept_code, limit: 50
        t.string :update_by, limit: 50
        t.datetime :update_time
        t.string :use_yn, limit: 1, default: "Y", null: false
      end

      add_index :adm_depts, :dept_code, unique: true
      add_index :adm_depts, [ :parent_dept_code, :dept_order, :dept_code ], name: "index_adm_depts_on_parent_order_and_code"
      add_index :adm_depts, :parent_dept_code
      add_index :adm_depts, :use_yn

      execute <<~SQL
        INSERT INTO adm_depts (create_by, create_time, dept_code, dept_nm, dept_order, dept_type, description, parent_dept_code, update_by, update_time, use_yn)
        SELECT create_by, create_time, dept_code, dept_nm, dept_order, dept_type, description, parent_dept_code, update_by, update_time, use_yn
        FROM adm_depts_legacy
      SQL

      drop_table :adm_depts_legacy
    end

    def rollback_adm_roles_to_code_pk
      return unless table_exists?(:adm_roles)

      rename_table :adm_roles, :adm_roles_with_id

      create_table :adm_roles, id: false do |t|
        t.string :create_by, limit: 50
        t.datetime :create_time
        t.text :description
        t.string :role_cd, limit: 50, null: false
        t.string :role_nm, limit: 100, null: false
        t.string :update_by, limit: 50
        t.datetime :update_time
        t.string :use_yn, limit: 1, default: "Y", null: false
      end

      add_index :adm_roles, :role_cd, unique: true
      add_index :adm_roles, :use_yn

      execute <<~SQL
        INSERT INTO adm_roles (create_by, create_time, description, role_cd, role_nm, update_by, update_time, use_yn)
        SELECT create_by, create_time, description, role_cd, role_nm, update_by, update_time, use_yn
        FROM adm_roles_with_id
      SQL

      drop_table :adm_roles_with_id
    end

    def rollback_adm_depts_to_code_pk
      return unless table_exists?(:adm_depts)

      rename_table :adm_depts, :adm_depts_with_id
      remove_index :adm_depts_with_id, name: "index_adm_depts_on_parent_order_and_code", if_exists: true

      create_table :adm_depts, id: false do |t|
        t.string :create_by, limit: 50
        t.datetime :create_time
        t.string :dept_code, limit: 50, null: false
        t.string :dept_nm, limit: 100, null: false
        t.integer :dept_order, default: 0, null: false
        t.string :dept_type, limit: 50
        t.text :description
        t.string :parent_dept_code, limit: 50
        t.string :update_by, limit: 50
        t.datetime :update_time
        t.string :use_yn, limit: 1, default: "Y", null: false
      end

      add_index :adm_depts, :dept_code, unique: true
      add_index :adm_depts, [ :parent_dept_code, :dept_order, :dept_code ], name: "index_adm_depts_on_parent_order_and_code"
      add_index :adm_depts, :parent_dept_code
      add_index :adm_depts, :use_yn

      execute <<~SQL
        INSERT INTO adm_depts (create_by, create_time, dept_code, dept_nm, dept_order, dept_type, description, parent_dept_code, update_by, update_time, use_yn)
        SELECT create_by, create_time, dept_code, dept_nm, dept_order, dept_type, description, parent_dept_code, update_by, update_time, use_yn
        FROM adm_depts_with_id
      SQL

      drop_table :adm_depts_with_id
    end
end
