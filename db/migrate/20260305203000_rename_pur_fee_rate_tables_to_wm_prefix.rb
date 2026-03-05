class RenamePurFeeRateTablesToWmPrefix < ActiveRecord::Migration[8.1]
  OLD_MASTER_TABLE = :tb_wm06001
  OLD_DETAIL_TABLE = :tb_wm06002
  NEW_MASTER_TABLE = :wm_pur_fee_rt_mngs
  NEW_DETAIL_TABLE = :wm_pur_fee_rt_mng_dtls
  OLD_DETAIL_INDEX = "idx_wm06002_rt_lineno"
  NEW_DETAIL_INDEX = "idx_wm_pur_fee_rt_mng_dtls_rt_lineno"

  def up
    if table_exists?(OLD_MASTER_TABLE) && !table_exists?(NEW_MASTER_TABLE)
      rename_table OLD_MASTER_TABLE, NEW_MASTER_TABLE
    end

    if table_exists?(OLD_DETAIL_TABLE) && !table_exists?(NEW_DETAIL_TABLE)
      rename_table OLD_DETAIL_TABLE, NEW_DETAIL_TABLE
    end

    if table_exists?(NEW_DETAIL_TABLE)
      if index_exists?(NEW_DETAIL_TABLE, name: OLD_DETAIL_INDEX) && !index_exists?(NEW_DETAIL_TABLE, name: NEW_DETAIL_INDEX)
        rename_index NEW_DETAIL_TABLE, OLD_DETAIL_INDEX, NEW_DETAIL_INDEX
      elsif !index_exists?(NEW_DETAIL_TABLE, [ :wrhs_exca_fee_rt_no, :lineno ], name: NEW_DETAIL_INDEX)
        add_index NEW_DETAIL_TABLE, [ :wrhs_exca_fee_rt_no, :lineno ], name: NEW_DETAIL_INDEX
      end
    end
  end

  def down
    if table_exists?(NEW_DETAIL_TABLE)
      if index_exists?(NEW_DETAIL_TABLE, name: NEW_DETAIL_INDEX) && !index_exists?(NEW_DETAIL_TABLE, name: OLD_DETAIL_INDEX)
        rename_index NEW_DETAIL_TABLE, NEW_DETAIL_INDEX, OLD_DETAIL_INDEX
      end
    end

    if table_exists?(NEW_DETAIL_TABLE) && !table_exists?(OLD_DETAIL_TABLE)
      rename_table NEW_DETAIL_TABLE, OLD_DETAIL_TABLE
    end

    if table_exists?(NEW_MASTER_TABLE) && !table_exists?(OLD_MASTER_TABLE)
      rename_table NEW_MASTER_TABLE, OLD_MASTER_TABLE
    end
  end
end
