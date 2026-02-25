class Wm::StockAttrLocQty < ApplicationRecord
  self.table_name = "tb_wm04003"

  def self.upsert_qty(corp_cd:, workpl_cd:, stock_attr_no:, loc_cd:, cust_cd:, item_cd:,
                      basis_unit_cls:, basis_unit_cd:, add_qty:, actor: "system")
    now = Time.current
    existing = find_by(corp_cd: corp_cd, workpl_cd: workpl_cd,
                       stock_attr_no: stock_attr_no, loc_cd: loc_cd)

    if existing
      existing.update!(
        qty:        existing.qty.to_f + add_qty.to_f,
        update_by:  actor,
        update_time: now
      )
    else
      create!(
        corp_cd:        corp_cd,
        workpl_cd:      workpl_cd,
        stock_attr_no:  stock_attr_no,
        loc_cd:         loc_cd,
        cust_cd:        cust_cd,
        item_cd:        item_cd,
        basis_unit_cls: basis_unit_cls,
        basis_unit_cd:  basis_unit_cd,
        qty:            add_qty.to_f,
        alloc_qty:      0,
        pick_qty:       0,
        hold_qty:       0,
        create_by:      actor,
        create_time:    now,
        update_by:      actor,
        update_time:    now
      )
    end
  end

  def available_qty
    qty.to_f - alloc_qty.to_f - pick_qty.to_f
  end
end
