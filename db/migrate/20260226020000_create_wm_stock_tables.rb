class CreateWmStockTables < ActiveRecord::Migration[8.1]
  def change
    # 재고속성 테이블
    create_table :tb_wm04001, id: false do |t|
      t.string :stock_attr_no,    limit: 10,  null: false, comment: "재고속성번호(PK)"
      t.string :corp_cd,          limit: 10,  null: false, comment: "법인코드"
      t.string :cust_cd,          limit: 20,  null: false, comment: "고객코드"
      t.string :item_cd,          limit: 30,  null: false, comment: "아이템코드"
      t.string :stock_attr_col01, limit: 100,              comment: "재고속성01"
      t.string :stock_attr_col02, limit: 100,              comment: "재고속성02"
      t.string :stock_attr_col03, limit: 100,              comment: "재고속성03"
      t.string :stock_attr_col04, limit: 100,              comment: "재고속성04"
      t.string :stock_attr_col05, limit: 100,              comment: "재고속성05"
      t.string :stock_attr_col06, limit: 100,              comment: "재고속성06"
      t.string :stock_attr_col07, limit: 100,              comment: "재고속성07"
      t.string :stock_attr_col08, limit: 100,              comment: "재고속성08"
      t.string :stock_attr_col09, limit: 100,              comment: "재고속성09"
      t.string :stock_attr_col10, limit: 100,              comment: "재고속성10"
      t.string :create_by,        limit: 50,               comment: "생성자"
      t.datetime :create_time,                             comment: "생성일시"
      t.string :update_by,        limit: 50,               comment: "수정자"
      t.datetime :update_time,                             comment: "수정일시"
    end

    execute "ALTER TABLE tb_wm04001 ADD PRIMARY KEY (stock_attr_no)" rescue nil

    add_index :tb_wm04001, [ :corp_cd, :cust_cd, :item_cd ], name: "idx_wm04001_corp_cust_item"

    # 재고속성번호별 재고 테이블
    create_table :tb_wm04002, id: false do |t|
      t.string  :corp_cd,         limit: 10,  null: false, comment: "법인코드(복합PK)"
      t.string  :workpl_cd,       limit: 20,  null: false, comment: "작업장코드(복합PK)"
      t.string  :stock_attr_no,   limit: 10,  null: false, comment: "재고속성번호(복합PK)"
      t.string  :cust_cd,         limit: 20,               comment: "고객코드"
      t.string  :item_cd,         limit: 30,               comment: "아이템코드"
      t.string  :basis_unit_cls,  limit: 10,               comment: "기본단위분류"
      t.string  :basis_unit_cd,   limit: 10,               comment: "기본단위코드"
      t.decimal :qty,             precision: 18, scale: 3, default: 0, null: false, comment: "물량"
      t.decimal :alloc_qty,       precision: 18, scale: 3, default: 0, null: false, comment: "할당물량"
      t.decimal :pick_qty,        precision: 18, scale: 3, default: 0, null: false, comment: "피킹물량"
      t.decimal :hold_qty,        precision: 18, scale: 3, default: 0, null: false, comment: "보류물량"
      t.string  :create_by,       limit: 50,               comment: "생성자"
      t.datetime :create_time,                             comment: "생성일시"
      t.string  :update_by,       limit: 50,               comment: "수정자"
      t.datetime :update_time,                             comment: "수정일시"
    end

    execute "ALTER TABLE tb_wm04002 ADD PRIMARY KEY (corp_cd, workpl_cd, stock_attr_no)" rescue nil

    # 속성/로케이션별 재고 테이블
    create_table :tb_wm04003, id: false do |t|
      t.string  :corp_cd,         limit: 10,  null: false, comment: "법인코드(복합PK)"
      t.string  :workpl_cd,       limit: 20,  null: false, comment: "작업장코드(복합PK)"
      t.string  :stock_attr_no,   limit: 10,  null: false, comment: "재고속성번호(복합PK)"
      t.string  :loc_cd,          limit: 20,  null: false, comment: "로케이션코드(복합PK)"
      t.string  :cust_cd,         limit: 20,               comment: "고객코드"
      t.string  :item_cd,         limit: 30,               comment: "아이템코드"
      t.string  :basis_unit_cls,  limit: 10,               comment: "기본단위분류"
      t.string  :basis_unit_cd,   limit: 10,               comment: "기본단위코드"
      t.decimal :qty,             precision: 18, scale: 3, default: 0, null: false, comment: "물량"
      t.decimal :alloc_qty,       precision: 18, scale: 3, default: 0, null: false, comment: "할당물량"
      t.decimal :pick_qty,        precision: 18, scale: 3, default: 0, null: false, comment: "피킹물량"
      t.decimal :hold_qty,        precision: 18, scale: 3, default: 0, null: false, comment: "보류물량"
      t.string  :create_by,       limit: 50,               comment: "생성자"
      t.datetime :create_time,                             comment: "생성일시"
      t.string  :update_by,       limit: 50,               comment: "수정자"
      t.datetime :update_time,                             comment: "수정일시"
    end

    execute "ALTER TABLE tb_wm04003 ADD PRIMARY KEY (corp_cd, workpl_cd, stock_attr_no, loc_cd)" rescue nil

    # 로케이션별 재고 테이블
    create_table :tb_wm04004, id: false do |t|
      t.string  :corp_cd,         limit: 10,  null: false, comment: "법인코드(복합PK)"
      t.string  :workpl_cd,       limit: 20,  null: false, comment: "작업장코드(복합PK)"
      t.string  :cust_cd,         limit: 20,  null: false, comment: "고객코드(복합PK)"
      t.string  :loc_cd,          limit: 20,  null: false, comment: "로케이션코드(복합PK)"
      t.string  :item_cd,         limit: 30,  null: false, comment: "아이템코드(복합PK)"
      t.string  :basis_unit_cls,  limit: 10,               comment: "기본단위분류"
      t.string  :basis_unit_cd,   limit: 10,               comment: "기본단위코드"
      t.decimal :qty,             precision: 18, scale: 3, default: 0, null: false, comment: "물량"
      t.decimal :alloc_qty,       precision: 18, scale: 3, default: 0, null: false, comment: "할당물량"
      t.decimal :pick_qty,        precision: 18, scale: 3, default: 0, null: false, comment: "피킹물량"
      t.decimal :hold_qty,        precision: 18, scale: 3, default: 0, null: false, comment: "보류물량"
      t.string  :create_by,       limit: 50,               comment: "생성자"
      t.datetime :create_time,                             comment: "생성일시"
      t.string  :update_by,       limit: 50,               comment: "수정자"
      t.datetime :update_time,                             comment: "수정일시"
    end

    execute "ALTER TABLE tb_wm04004 ADD PRIMARY KEY (corp_cd, workpl_cd, cust_cd, loc_cd, item_cd)" rescue nil
  end
end
