class AddManualCompletionFieldsToOmOrders < ActiveRecord::Migration[8.1]
  def up
    return unless table_exists?(:om_orders)

    if !column_exists?(:om_orders, :ord_cmpt_div_cd)
      add_column :om_orders, :ord_cmpt_div_cd, :string, limit: 30
      add_index :om_orders, :ord_cmpt_div_cd
    end

    if !column_exists?(:om_orders, :ord_cmpt_dtm)
      add_column :om_orders, :ord_cmpt_dtm, :datetime
      add_index :om_orders, :ord_cmpt_dtm
    end

    if !column_exists?(:om_orders, :manl_cmpt_rsn)
      add_column :om_orders, :manl_cmpt_rsn, :string, limit: 500
    end
  end

  def down
    return unless table_exists?(:om_orders)

    if column_exists?(:om_orders, :manl_cmpt_rsn)
      remove_column :om_orders, :manl_cmpt_rsn
    end

    if column_exists?(:om_orders, :ord_cmpt_dtm)
      remove_index :om_orders, :ord_cmpt_dtm if index_exists?(:om_orders, :ord_cmpt_dtm)
      remove_column :om_orders, :ord_cmpt_dtm
    end

    if column_exists?(:om_orders, :ord_cmpt_div_cd)
      remove_index :om_orders, :ord_cmpt_div_cd if index_exists?(:om_orders, :ord_cmpt_div_cd)
      remove_column :om_orders, :ord_cmpt_div_cd
    end
  end
end
