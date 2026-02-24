class ChangeAdmCodeDetailsReferenceAndAddAttributes < ActiveRecord::Migration[8.1]
  def up
    add_column :adm_code_details, :upper_code, :string, limit: 50
    add_column :adm_code_details, :upper_detail_code, :string, limit: 50
    add_column :adm_code_details, :rmk, :string, limit: 500
    add_column :adm_code_details, :attr1, :string, limit: 200
    add_column :adm_code_details, :attr2, :string, limit: 200
    add_column :adm_code_details, :attr3, :string, limit: 200
    add_column :adm_code_details, :attr4, :string, limit: 200
    add_column :adm_code_details, :attr5, :string, limit: 200

    execute <<~SQL.squish
      UPDATE adm_code_details
      SET upper_detail_code = ref_code
      WHERE ref_code IS NOT NULL
    SQL

    remove_column :adm_code_details, :ref_code, :string, limit: 50
  end

  def down
    add_column :adm_code_details, :ref_code, :string, limit: 50

    execute <<~SQL.squish
      UPDATE adm_code_details
      SET ref_code = upper_detail_code
      WHERE upper_detail_code IS NOT NULL
    SQL

    remove_column :adm_code_details, :attr5, :string, limit: 200
    remove_column :adm_code_details, :attr4, :string, limit: 200
    remove_column :adm_code_details, :attr3, :string, limit: 200
    remove_column :adm_code_details, :attr2, :string, limit: 200
    remove_column :adm_code_details, :attr1, :string, limit: 200
    remove_column :adm_code_details, :rmk, :string, limit: 500
    remove_column :adm_code_details, :upper_detail_code, :string, limit: 50
    remove_column :adm_code_details, :upper_code, :string, limit: 50
  end
end
