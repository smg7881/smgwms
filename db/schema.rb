# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_02_26_030000) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "adm_code_details", force: :cascade do |t|
    t.string "attr1", limit: 200
    t.string "attr2", limit: 200
    t.string "attr3", limit: 200
    t.string "attr4", limit: 200
    t.string "attr5", limit: 200
    t.string "code", limit: 50, null: false
    t.string "create_by", limit: 50
    t.datetime "create_time"
    t.string "detail_code", limit: 50, null: false
    t.string "detail_code_name", limit: 100, null: false
    t.string "rmk", limit: 500
    t.string "short_name", limit: 100
    t.integer "sort_order", default: 0, null: false
    t.string "update_by", limit: 50
    t.datetime "update_time"
    t.string "upper_code", limit: 50
    t.string "upper_detail_code", limit: 50
    t.string "use_yn", limit: 1, default: "Y", null: false
    t.index ["code", "detail_code"], name: "index_adm_code_details_on_code_and_detail_code", unique: true
    t.index ["code", "sort_order", "detail_code"], name: "index_adm_code_details_on_code_order_and_detail_code"
    t.index ["code"], name: "index_adm_code_details_on_code"
    t.index ["use_yn"], name: "index_adm_code_details_on_use_yn"
  end

  create_table "adm_code_headers", force: :cascade do |t|
    t.string "code", limit: 50, null: false
    t.string "code_name", limit: 100, null: false
    t.string "create_by", limit: 50
    t.datetime "create_time"
    t.string "rmk", limit: 500
    t.string "sys_sctn_cd", limit: 30
    t.string "update_by", limit: 50
    t.datetime "update_time"
    t.string "use_yn", limit: 1, default: "Y", null: false
    t.index ["code"], name: "index_adm_code_headers_on_code", unique: true
    t.index ["use_yn"], name: "index_adm_code_headers_on_use_yn"
  end

  create_table "adm_depts", force: :cascade do |t|
    t.string "create_by", limit: 50
    t.datetime "create_time"
    t.string "dept_code", limit: 50, null: false
    t.string "dept_nm", limit: 100, null: false
    t.integer "dept_order", default: 0, null: false
    t.string "dept_type", limit: 50
    t.text "description"
    t.string "parent_dept_code", limit: 50
    t.string "update_by", limit: 50
    t.datetime "update_time"
    t.string "use_yn", limit: 1, default: "Y", null: false
    t.index ["dept_code"], name: "index_adm_depts_on_dept_code", unique: true
    t.index ["parent_dept_code", "dept_order", "dept_code"], name: "index_adm_depts_on_parent_order_and_code"
    t.index ["parent_dept_code"], name: "index_adm_depts_on_parent_dept_code"
    t.index ["use_yn"], name: "index_adm_depts_on_use_yn"
  end

  create_table "adm_login_histories", force: :cascade do |t|
    t.string "browser", limit: 100
    t.string "failure_reason", limit: 200
    t.string "ip_address", limit: 45
    t.boolean "login_success", null: false
    t.datetime "login_time", null: false
    t.string "os", limit: 100
    t.string "user_agent", limit: 500
    t.string "user_id_code", limit: 16
    t.string "user_nm", limit: 20
    t.index ["login_success"], name: "index_adm_login_histories_on_login_success"
    t.index ["login_time"], name: "index_adm_login_histories_on_login_time"
    t.index ["user_id_code", "login_time"], name: "index_adm_login_histories_on_user_id_code_and_login_time"
    t.index ["user_id_code"], name: "index_adm_login_histories_on_user_id_code"
  end

  create_table "adm_menu_logs", force: :cascade do |t|
    t.datetime "access_time", null: false
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.string "menu_id"
    t.string "menu_name"
    t.string "menu_path"
    t.string "referrer"
    t.string "session_id"
    t.datetime "updated_at", null: false
    t.text "user_agent"
    t.string "user_id"
    t.string "user_name"
    t.index ["access_time"], name: "index_adm_menu_logs_on_access_time"
    t.index ["menu_id"], name: "index_adm_menu_logs_on_menu_id"
    t.index ["session_id"], name: "index_adm_menu_logs_on_session_id"
    t.index ["user_id"], name: "index_adm_menu_logs_on_user_id"
  end

  create_table "adm_menus", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "menu_cd", limit: 20, null: false
    t.string "menu_icon", limit: 50
    t.integer "menu_level", default: 1, null: false
    t.string "menu_nm", limit: 100, null: false
    t.string "menu_type", limit: 10, default: "MENU", null: false
    t.string "menu_url", limit: 200
    t.string "parent_cd", limit: 20
    t.integer "sort_order", default: 0, null: false
    t.string "tab_id", limit: 50
    t.datetime "updated_at", null: false
    t.string "use_yn", limit: 1, default: "Y", null: false
    t.index ["menu_cd"], name: "index_adm_menus_on_menu_cd", unique: true
    t.index ["parent_cd", "sort_order", "menu_cd"], name: "index_adm_menus_on_parent_cd_and_sort_order_and_menu_cd"
    t.index ["parent_cd"], name: "index_adm_menus_on_parent_cd"
  end

  create_table "adm_notices", force: :cascade do |t|
    t.string "category_code", limit: 50, null: false
    t.text "content", null: false
    t.string "create_by", limit: 50
    t.datetime "create_time"
    t.date "end_date"
    t.string "is_published", limit: 1, default: "Y", null: false
    t.string "is_top_fixed", limit: 1, default: "N", null: false
    t.date "start_date"
    t.string "title", limit: 200, null: false
    t.string "update_by", limit: 50
    t.datetime "update_time"
    t.integer "view_count", default: 0, null: false
    t.index ["category_code"], name: "index_adm_notices_on_category_code"
    t.index ["create_time"], name: "index_adm_notices_on_create_time"
    t.index ["is_published"], name: "index_adm_notices_on_is_published"
    t.index ["is_top_fixed"], name: "index_adm_notices_on_is_top_fixed"
  end

  create_table "adm_roles", force: :cascade do |t|
    t.string "create_by", limit: 50
    t.datetime "create_time"
    t.text "description"
    t.string "role_cd", limit: 50, null: false
    t.string "role_nm", limit: 100, null: false
    t.string "update_by", limit: 50
    t.datetime "update_time"
    t.string "use_yn", limit: 1, default: "Y", null: false
    t.index ["role_cd"], name: "index_adm_roles_on_role_cd", unique: true
    t.index ["use_yn"], name: "index_adm_roles_on_use_yn"
  end

  create_table "adm_user_menu_permissions", force: :cascade do |t|
    t.string "create_by", limit: 50
    t.datetime "create_time"
    t.string "menu_cd", limit: 20, null: false
    t.string "update_by", limit: 50
    t.datetime "update_time"
    t.string "use_yn", limit: 1, default: "Y", null: false
    t.integer "user_id", null: false
    t.index ["menu_cd"], name: "index_adm_user_menu_permissions_on_menu_cd"
    t.index ["use_yn"], name: "index_adm_user_menu_permissions_on_use_yn"
    t.index ["user_id", "menu_cd"], name: "index_user_menu_permissions_on_user_and_menu", unique: true
    t.index ["user_id"], name: "index_adm_user_menu_permissions_on_user_id"
  end

  create_table "adm_users", force: :cascade do |t|
    t.string "address"
    t.datetime "created_at", null: false
    t.integer "dept_id"
    t.string "dept_nm"
    t.string "detail_address"
    t.string "email_address"
    t.date "hire_date"
    t.string "job_title_cd"
    t.string "password_digest"
    t.string "phone"
    t.string "position_cd"
    t.date "resign_date"
    t.integer "role_id"
    t.datetime "updated_at", null: false
    t.string "user_id_code"
    t.string "user_nm"
    t.string "work_status", default: "ACTIVE"
    t.index ["dept_id"], name: "index_adm_users_on_dept_id"
    t.index ["role_id"], name: "index_adm_users_on_role_id"
    t.index ["user_id_code"], name: "index_adm_users_on_user_id_code", unique: true
    t.index ["work_status"], name: "index_adm_users_on_work_status"
  end

  create_table "excel_import_tasks", force: :cascade do |t|
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.text "error_summary"
    t.integer "failed_rows", default: 0, null: false
    t.integer "requested_by_id"
    t.string "resource_key", null: false
    t.bigint "source_byte_size"
    t.string "source_filename"
    t.datetime "started_at"
    t.string "status", default: "queued", null: false
    t.integer "success_rows", default: 0, null: false
    t.integer "total_rows", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["requested_by_id"], name: "index_excel_import_tasks_on_requested_by_id"
    t.index ["resource_key", "created_at"], name: "index_excel_import_tasks_on_resource_key_and_created_at"
    t.index ["status"], name: "index_excel_import_tasks_on_status"
  end

  create_table "om_customer_order_officers", force: :cascade do |t|
    t.string "create_by", limit: 50
    t.datetime "create_time"
    t.string "cust_cd", limit: 20, null: false
    t.string "cust_nm", limit: 120
    t.string "cust_ofcr_mbp_no", limit: 30
    t.string "cust_ofcr_nm", limit: 100, null: false
    t.string "cust_ofcr_tel_no", limit: 30
    t.string "exp_imp_dom_sctn_cd", limit: 30
    t.string "ord_chrg_dept_cd", limit: 50, default: "", null: false
    t.string "ord_chrg_dept_nm", limit: 100
    t.string "update_by", limit: 50
    t.datetime "update_time"
    t.string "use_yn", limit: 1, default: "Y", null: false
    t.index ["cust_cd"], name: "index_om_customer_order_officers_on_cust_cd"
    t.index ["ord_chrg_dept_cd", "cust_cd", "exp_imp_dom_sctn_cd", "cust_ofcr_nm"], name: "idx_om_cust_ord_ofcr_unique", unique: true
    t.index ["ord_chrg_dept_cd"], name: "index_om_customer_order_officers_on_ord_chrg_dept_cd"
    t.index ["use_yn"], name: "index_om_customer_order_officers_on_use_yn"
  end

  create_table "om_customer_system_configs", force: :cascade do |t|
    t.string "config_key", limit: 100, null: false
    t.string "config_value", limit: 500
    t.string "create_by", limit: 50
    t.datetime "create_time"
    t.string "cust_cd", limit: 20, default: "", null: false
    t.string "cust_nm", limit: 120
    t.string "grp_cd", limit: 50
    t.string "lclas_cd", limit: 50, default: "ORD_RECV", null: false
    t.string "mclas_cd", limit: 50, default: "REQUIRED", null: false
    t.string "module_nm", limit: 150
    t.string "sclas_cd", limit: 50, default: "ITEM_NM", null: false
    t.string "setup_sctn_cd", limit: 50, default: "VALIDATE", null: false
    t.string "setup_unit_cd", limit: 30, default: "SYSTEM", null: false
    t.string "setup_value", limit: 200
    t.string "update_by", limit: 50
    t.datetime "update_time"
    t.string "upper_grp_cd", limit: 50
    t.string "use_yn", limit: 1, default: "Y", null: false
    t.index ["cust_cd", "grp_cd", "config_key"], name: "idx_om_cust_sys_cfg_unique", unique: true
    t.index ["cust_cd"], name: "index_om_customer_system_configs_on_cust_cd"
    t.index ["setup_unit_cd", "cust_cd", "lclas_cd", "mclas_cd", "sclas_cd", "setup_sctn_cd"], name: "index_om_customer_system_configs_on_unique_key", unique: true
    t.index ["setup_unit_cd"], name: "index_om_customer_system_configs_on_setup_unit_cd"
    t.index ["use_yn"], name: "index_om_customer_system_configs_on_use_yn"
  end

  create_table "om_internal_order_items", force: :cascade do |t|
    t.string "basis_unit_cd", limit: 20
    t.string "create_by", limit: 50
    t.datetime "create_time"
    t.integer "internal_order_id", null: false
    t.string "item_cd", limit: 30, null: false
    t.string "item_nm", limit: 100
    t.decimal "ord_qty", precision: 18, scale: 4, default: "0.0"
    t.decimal "ord_vol", precision: 18, scale: 4, default: "0.0"
    t.decimal "ord_wgt", precision: 18, scale: 4, default: "0.0"
    t.string "qty_unit_cd", limit: 20
    t.integer "seq_no", null: false
    t.string "update_by", limit: 50
    t.datetime "update_time"
    t.string "vol_unit_cd", limit: 20
    t.string "wgt_unit_cd", limit: 20
    t.index ["internal_order_id", "seq_no"], name: "idx_om_internal_order_items_on_order_seq", unique: true
    t.index ["internal_order_id"], name: "index_om_internal_order_items_on_internal_order_id"
  end

  create_table "om_internal_orders", force: :cascade do |t|
    t.string "aptd_req_dtm", limit: 14
    t.string "arv_addr", limit: 200
    t.string "arv_cd", limit: 30
    t.string "arv_type_cd", limit: 20
    t.string "arv_zip_cd", limit: 10
    t.string "bilg_cust_cd", limit: 20
    t.string "cancel_yn", limit: 1, default: "N", null: false
    t.string "create_by", limit: 50
    t.datetime "create_time"
    t.string "ctrt_cust_cd", limit: 20
    t.string "ctrt_no", limit: 30
    t.string "dpt_addr", limit: 200
    t.string "dpt_cd", limit: 30
    t.string "dpt_type_cd", limit: 20
    t.string "dpt_zip_cd", limit: 10
    t.string "ord_exec_dept_cd", limit: 20
    t.string "ord_exec_dept_nm", limit: 100
    t.string "ord_exec_ofcr_cd", limit: 20
    t.string "ord_exec_ofcr_nm", limit: 100
    t.string "ord_no", limit: 30, null: false
    t.string "ord_reason_cd", limit: 20
    t.string "ord_stat_cd", limit: 20, default: "WAIT", null: false
    t.string "ord_type_cd", limit: 20
    t.text "remk"
    t.string "strt_req_ymd", limit: 8
    t.string "update_by", limit: 50
    t.datetime "update_time"
    t.string "wait_ord_internal_yn", limit: 1, default: "N", null: false
    t.index ["cancel_yn"], name: "index_om_internal_orders_on_cancel_yn"
    t.index ["ord_no"], name: "index_om_internal_orders_on_ord_no", unique: true
    t.index ["ord_stat_cd"], name: "index_om_internal_orders_on_ord_stat_cd"
    t.index ["wait_ord_internal_yn"], name: "index_om_internal_orders_on_wait_ord_internal_yn"
  end

  create_table "om_order_change_histories", force: :cascade do |t|
    t.string "after_val", limit: 300
    t.string "before_val", limit: 300
    t.string "chg_by", limit: 50
    t.string "chg_rsn", limit: 500
    t.datetime "chg_time"
    t.string "chg_type_cd", limit: 30
    t.string "create_by", limit: 50
    t.datetime "create_time"
    t.string "ord_no", limit: 30, null: false
    t.integer "seq", null: false
    t.string "update_by", limit: 50
    t.datetime "update_time"
    t.string "use_yn", limit: 1, default: "Y", null: false
    t.index ["chg_type_cd"], name: "index_om_order_change_histories_on_chg_type_cd"
    t.index ["ord_no", "seq"], name: "idx_om_order_change_history_unique", unique: true
  end

  create_table "om_order_officers", force: :cascade do |t|
    t.string "create_by", limit: 50
    t.datetime "create_time"
    t.string "cust_cd", limit: 20
    t.string "cust_nm", limit: 120
    t.string "exp_imp_dom_sctn_cd", limit: 30
    t.string "mbp_no", limit: 30
    t.string "ofcr_cd", limit: 30, null: false
    t.string "ofcr_nm", limit: 100, null: false
    t.string "ord_chrg_dept_cd", limit: 50, default: "", null: false
    t.string "ord_chrg_dept_nm", limit: 100
    t.string "tel_no", limit: 30
    t.string "update_by", limit: 50
    t.datetime "update_time"
    t.string "use_yn", limit: 1, default: "Y", null: false
    t.index ["cust_cd"], name: "index_om_order_officers_on_cust_cd"
    t.index ["ord_chrg_dept_cd", "cust_cd", "exp_imp_dom_sctn_cd", "ofcr_cd"], name: "idx_om_ord_ofcr_unique", unique: true
    t.index ["ord_chrg_dept_cd"], name: "index_om_order_officers_on_ord_chrg_dept_cd"
    t.index ["use_yn"], name: "index_om_order_officers_on_use_yn"
  end

  create_table "om_order_progresses", force: :cascade do |t|
    t.string "create_by", limit: 50
    t.datetime "create_time"
    t.datetime "last_update_time"
    t.string "latest_work_step", limit: 120
    t.string "ord_no", limit: 30, null: false
    t.string "progress_stat_cd", limit: 30
    t.string "progress_step_cd", limit: 30, null: false
    t.string "update_by", limit: 50
    t.datetime "update_time"
    t.string "use_yn", limit: 1, default: "Y", null: false
    t.index ["ord_no", "progress_step_cd"], name: "idx_om_order_progress_unique", unique: true
    t.index ["progress_stat_cd"], name: "index_om_order_progresses_on_progress_stat_cd"
  end

  create_table "om_order_transmission_logs", force: :cascade do |t|
    t.string "asign_idct_no", limit: 40
    t.string "create_by", limit: 50
    t.datetime "create_time"
    t.string "err_msg", limit: 500
    t.string "ord_no", limit: 30, null: false
    t.string "rcv_hms", limit: 8
    t.string "trms_hms", limit: 8
    t.string "trms_yn", limit: 1, default: "N", null: false
    t.string "update_by", limit: 50
    t.datetime "update_time"
    t.string "use_yn", limit: 1, default: "Y", null: false
    t.index ["ord_no"], name: "index_om_order_transmission_logs_on_ord_no"
    t.index ["trms_yn"], name: "index_om_order_transmission_logs_on_trms_yn"
  end

  create_table "om_orders", force: :cascade do |t|
    t.date "aptd_req_ymd"
    t.string "arv_ar_cd", limit: 30
    t.string "arv_ar_nm", limit: 150
    t.string "asign_idct_no", limit: 40
    t.string "billing_cust_cd", limit: 20
    t.string "contract_cust_cd", limit: 20
    t.string "create_by", limit: 50
    t.datetime "create_time"
    t.string "cust_cd", limit: 20
    t.string "cust_nm", limit: 120
    t.string "cust_ord_no", limit: 40
    t.string "dpt_ar_cd", limit: 30
    t.string "dpt_ar_nm", limit: 150
    t.string "item_cd", limit: 40
    t.string "item_nm", limit: 150
    t.datetime "last_update_time"
    t.string "manl_cmpt_rsn", limit: 500
    t.string "ord_cmpt_div_cd", limit: 30
    t.datetime "ord_cmpt_dtm"
    t.string "ord_exe_dept_cd", limit: 50
    t.string "ord_kind_nm", limit: 120
    t.string "ord_no", limit: 30, null: false
    t.decimal "ord_qty", precision: 14, scale: 3
    t.string "ord_stat_cd", limit: 30
    t.string "ord_type_cd", limit: 30
    t.string "ord_type_nm", limit: 120
    t.decimal "ord_vol", precision: 14, scale: 3
    t.decimal "ord_wgt", precision: 14, scale: 3
    t.string "update_by", limit: 50
    t.datetime "update_time"
    t.string "use_yn", limit: 1, default: "Y", null: false
    t.string "work_stat_cd", limit: 30
    t.index ["cust_cd"], name: "index_om_orders_on_cust_cd"
    t.index ["ord_cmpt_div_cd"], name: "index_om_orders_on_ord_cmpt_div_cd"
    t.index ["ord_cmpt_dtm"], name: "index_om_orders_on_ord_cmpt_dtm"
    t.index ["ord_no"], name: "index_om_orders_on_ord_no", unique: true
    t.index ["ord_stat_cd"], name: "index_om_orders_on_ord_stat_cd"
    t.index ["work_stat_cd"], name: "index_om_orders_on_work_stat_cd"
  end

  create_table "om_pre_order_errors", force: :cascade do |t|
    t.string "create_by", limit: 50
    t.datetime "create_time"
    t.string "cust_ord_no", limit: 40
    t.string "err_msg", limit: 500
    t.string "err_type_cd", limit: 30
    t.string "item_cd", limit: 40
    t.integer "line_no", null: false
    t.string "resolved_yn", limit: 1, default: "N", null: false
    t.string "update_by", limit: 50
    t.datetime "update_time"
    t.string "upload_batch_no", limit: 40, null: false
    t.string "use_yn", limit: 1, default: "Y", null: false
    t.index ["err_type_cd"], name: "index_om_pre_order_errors_on_err_type_cd"
    t.index ["upload_batch_no", "line_no"], name: "idx_om_pre_ord_error_unique", unique: true
  end

  create_table "om_pre_order_receptions", force: :cascade do |t|
    t.string "bef_ord_no", limit: 30, null: false
    t.string "create_by", limit: 50
    t.datetime "create_time"
    t.string "cust_cd", limit: 20
    t.string "cust_nm", limit: 120
    t.string "cust_ord_no", limit: 40
    t.string "item_cd", limit: 40
    t.string "item_nm", limit: 150
    t.decimal "qty", precision: 14, scale: 3
    t.string "status_cd", limit: 30
    t.string "update_by", limit: 50
    t.datetime "update_time"
    t.string "use_yn", limit: 1, default: "Y", null: false
    t.decimal "vol", precision: 14, scale: 3
    t.decimal "wgt", precision: 14, scale: 3
    t.index ["bef_ord_no"], name: "index_om_pre_order_receptions_on_bef_ord_no", unique: true
    t.index ["cust_ord_no"], name: "index_om_pre_order_receptions_on_cust_ord_no"
    t.index ["status_cd"], name: "index_om_pre_order_receptions_on_status_cd"
  end

  create_table "om_pre_order_upload_batches", force: :cascade do |t|
    t.string "create_by", limit: 50
    t.datetime "create_time"
    t.string "cust_cd", limit: 20
    t.string "cust_nm", limit: 120
    t.integer "error_cnt", default: 0, null: false
    t.string "file_nm", limit: 255
    t.string "update_by", limit: 50
    t.datetime "update_time"
    t.string "upload_batch_no", limit: 40, null: false
    t.string "upload_stat_cd", limit: 30
    t.string "use_yn", limit: 1, default: "Y", null: false
    t.index ["upload_batch_no"], name: "index_om_pre_order_upload_batches_on_upload_batch_no", unique: true
    t.index ["upload_stat_cd"], name: "index_om_pre_order_upload_batches_on_upload_stat_cd"
  end

  create_table "om_work_route_results", force: :cascade do |t|
    t.string "create_by", limit: 50
    t.datetime "create_time"
    t.string "ord_no", limit: 30, null: false
    t.decimal "rslt_qty", precision: 14, scale: 3
    t.decimal "rslt_vol", precision: 14, scale: 3
    t.decimal "rslt_wgt", precision: 14, scale: 3
    t.string "rslt_yn", limit: 1, default: "N", null: false
    t.string "update_by", limit: 50
    t.datetime "update_time"
    t.string "use_yn", limit: 1, default: "Y", null: false
    t.datetime "work_end_time"
    t.string "work_route_no", limit: 40, null: false
    t.datetime "work_strt_time"
    t.index ["rslt_yn"], name: "index_om_work_route_results_on_rslt_yn"
    t.index ["work_route_no", "ord_no"], name: "idx_om_work_route_result_unique", unique: true
  end

  create_table "om_work_routes", force: :cascade do |t|
    t.string "arv_ar_nm", limit: 150
    t.string "create_by", limit: 50
    t.datetime "create_time"
    t.string "dpt_ar_nm", limit: 150
    t.string "ord_no", limit: 30, null: false
    t.decimal "ord_vol", precision: 14, scale: 3
    t.string "update_by", limit: 50
    t.datetime "update_time"
    t.string "use_yn", limit: 1, default: "Y", null: false
    t.string "work_dept_cd", limit: 50
    t.date "work_end_date"
    t.string "work_route_nm", limit: 150
    t.string "work_route_no", limit: 40, null: false
    t.string "work_step", limit: 50
    t.date "work_strt_date"
    t.index ["ord_no"], name: "index_om_work_routes_on_ord_no"
    t.index ["work_route_no"], name: "index_om_work_routes_on_work_route_no", unique: true
  end

  create_table "posts", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.string "title"
    t.datetime "updated_at", null: false
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["token"], name: "index_sessions_on_token", unique: true
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "std_approval_requests", force: :cascade do |t|
    t.datetime "apv_apv_ymd"
    t.text "apv_opi"
    t.text "apv_req_conts"
    t.string "apv_req_no", limit: 20, null: false
    t.datetime "apv_req_ymd"
    t.string "apv_reqr", limit: 50, null: false
    t.string "apv_stat_cd", limit: 30, default: "REQUESTED", null: false
    t.string "apv_type_cd", limit: 30
    t.string "apver_chg", limit: 50
    t.string "asmt_apver", limit: 50, null: false
    t.string "corp_cd", limit: 20, null: false
    t.string "create_by", limit: 50
    t.datetime "create_time"
    t.string "menu_cd", limit: 30
    t.string "menu_nm", limit: 120, null: false
    t.string "update_by", limit: 50
    t.datetime "update_time"
    t.string "use_yn", limit: 1, default: "Y", null: false
    t.string "user_cd", limit: 50
    t.index ["apv_req_no"], name: "index_std_approval_requests_on_apv_req_no", unique: true
    t.index ["apv_req_ymd"], name: "index_std_approval_requests_on_apv_req_ymd"
    t.index ["apv_reqr"], name: "index_std_approval_requests_on_apv_reqr"
    t.index ["apv_stat_cd"], name: "index_std_approval_requests_on_apv_stat_cd"
    t.index ["asmt_apver"], name: "index_std_approval_requests_on_asmt_apver"
  end

  create_table "std_approvals", force: :cascade do |t|
    t.string "apv_delegate", limit: 50
    t.string "apv_delegt_yn", limit: 1, default: "N", null: false
    t.string "apv_type_cd", limit: 30
    t.string "asmt_apver_yn", limit: 1, default: "Y", null: false
    t.string "chrg_apver", limit: 50
    t.string "col1_cd", limit: 60
    t.string "col2_cd", limit: 60
    t.string "col3_cd", limit: 60
    t.string "col4_cd", limit: 60
    t.string "col5_cd", limit: 60
    t.string "corp_cd", limit: 20, null: false
    t.string "corp_nm", limit: 120
    t.string "create_by", limit: 50
    t.datetime "create_time"
    t.string "menu_cd", limit: 30, null: false
    t.string "menu_nm", limit: 120, null: false
    t.string "not_asmt_apver_resp", limit: 50
    t.string "rmk", limit: 500
    t.string "table_cd", limit: 60
    t.string "update_by", limit: 50
    t.datetime "update_time"
    t.string "use_yn", limit: 1, default: "Y", null: false
    t.index ["corp_cd", "menu_cd"], name: "index_std_approvals_on_corp_cd_and_menu_cd", unique: true
    t.index ["menu_nm"], name: "index_std_approvals_on_menu_nm"
    t.index ["use_yn"], name: "index_std_approvals_on_use_yn"
  end

  create_table "std_business_certificates", force: :cascade do |t|
    t.string "attached_file_nm", limit: 255
    t.string "bizcond_cd", limit: 120
    t.string "bizman_yn_cd", limit: 20, null: false
    t.string "bzac_cd", limit: 20, null: false
    t.string "bzac_nm", limit: 200
    t.date "clbiz_ymd"
    t.string "compreg_slip", limit: 30, null: false
    t.string "corp_reg_no_cd", limit: 50
    t.string "create_by", limit: 50
    t.datetime "create_time"
    t.string "dtl_addr_cd", limit: 300
    t.string "dup_bzac_yn_cd", limit: 1, default: "N", null: false
    t.string "indstype_cd", limit: 120
    t.text "rmk"
    t.string "rptr_nm_cd", limit: 120, null: false
    t.string "store_nm_cd", limit: 200, null: false
    t.string "update_by", limit: 50
    t.datetime "update_time"
    t.string "use_yn_cd", limit: 1, default: "Y", null: false
    t.string "zip_cd", limit: 20
    t.string "zipaddr_cd", limit: 300
    t.index ["bzac_cd"], name: "index_std_business_certificates_on_bzac_cd", unique: true
    t.index ["compreg_slip"], name: "index_std_business_certificates_on_compreg_slip"
    t.index ["use_yn_cd"], name: "index_std_business_certificates_on_use_yn_cd"
  end

  create_table "std_bzac_mst", force: :cascade do |t|
    t.string "acnt_no_cd", limit: 50
    t.string "addr_cd", limit: 300
    t.string "addr_dtl_cd", limit: 300
    t.date "aply_end_day_cd"
    t.date "aply_strt_day_cd", null: false
    t.string "bilg_bzac_cd", limit: 20
    t.string "bizman_no", limit: 20, null: false
    t.string "branch_yn_cd", limit: 1, default: "N", null: false
    t.string "bzac_cd", limit: 20, null: false
    t.string "bzac_kind_cd", limit: 50, null: false
    t.string "bzac_nm", limit: 200, null: false
    t.string "bzac_sctn_cd", limit: 50, null: false
    t.string "bzac_sctn_grp_cd", limit: 50, null: false
    t.string "create_by", limit: 50
    t.datetime "create_time"
    t.string "ctry_cd", limit: 10, default: "KR", null: false
    t.string "elec_taxbill_yn_cd", limit: 1, default: "N", null: false
    t.string "fnc_or_cd", limit: 50
    t.string "if_yn_cd", limit: 1, default: "N", null: false
    t.string "mngt_corp_cd", limit: 50, null: false
    t.string "mngt_corp_nm", limit: 100
    t.string "pur_bzac_yn_cd", limit: 1, default: "Y", null: false
    t.text "remk"
    t.string "rpt_bzac_cd", limit: 20
    t.string "rpt_sales_emp_cd", limit: 50, null: false
    t.string "rpt_sales_emp_nm", limit: 100
    t.string "sell_bzac_yn_cd", limit: 1, default: "Y", null: false
    t.string "tpl_logis_yn_cd", limit: 1, default: "N", null: false
    t.string "update_by", limit: 50
    t.datetime "update_time"
    t.string "upper_bzac_cd", limit: 20
    t.string "use_yn_cd", limit: 1, default: "Y", null: false
    t.string "zip_cd", limit: 20
    t.index ["bizman_no"], name: "index_std_bzac_mst_on_bizman_no"
    t.index ["bzac_cd"], name: "index_std_bzac_mst_on_bzac_cd", unique: true
    t.index ["bzac_nm"], name: "index_std_bzac_mst_on_bzac_nm"
    t.index ["bzac_sctn_cd"], name: "index_std_bzac_mst_on_bzac_sctn_cd"
    t.index ["bzac_sctn_grp_cd"], name: "index_std_bzac_mst_on_bzac_sctn_grp_cd"
    t.index ["mngt_corp_cd"], name: "index_std_bzac_mst_on_mngt_corp_cd"
    t.index ["use_yn_cd"], name: "index_std_bzac_mst_on_use_yn_cd"
  end

  create_table "std_bzac_ofcr", force: :cascade do |t|
    t.string "bzac_cd", limit: 20, null: false
    t.string "create_by", limit: 50
    t.datetime "create_time"
    t.string "email_cd", limit: 120
    t.string "mbp_no_cd", limit: 30
    t.string "nm_cd", limit: 100, null: false
    t.string "ofic_telno_cd", limit: 30
    t.string "rpt_yn_cd", limit: 1, default: "N", null: false
    t.integer "seq_cd", null: false
    t.string "update_by", limit: 50
    t.datetime "update_time"
    t.string "use_yn_cd", limit: 1, default: "Y", null: false
    t.index ["bzac_cd", "seq_cd"], name: "index_std_bzac_ofcr_on_bzac_cd_and_seq_cd", unique: true
    t.index ["bzac_cd"], name: "index_std_bzac_ofcr_on_bzac_cd"
    t.index ["use_yn_cd"], name: "index_std_bzac_ofcr_on_use_yn_cd"
  end

  create_table "std_bzac_workpl", force: :cascade do |t|
    t.string "bzac_cd", limit: 20, null: false
    t.string "create_by", limit: 50
    t.datetime "create_time"
    t.string "ofcr_cd", limit: 50
    t.integer "seq_cd", null: false
    t.string "update_by", limit: 50
    t.datetime "update_time"
    t.string "use_yn_cd", limit: 1, default: "Y", null: false
    t.string "workpl_nm_cd", limit: 120, null: false
    t.string "workpl_sctn_cd", limit: 50
    t.index ["bzac_cd", "seq_cd"], name: "index_std_bzac_workpl_on_bzac_cd_and_seq_cd", unique: true
    t.index ["bzac_cd"], name: "index_std_bzac_workpl_on_bzac_cd"
    t.index ["use_yn_cd"], name: "index_std_bzac_workpl_on_use_yn_cd"
  end

  create_table "std_client_item_codes", force: :cascade do |t|
    t.string "basis_unit_cd", limit: 20
    t.string "bzac_cd", limit: 20, null: false
    t.datetime "chgdt", null: false
    t.string "create_by", limit: 50
    t.datetime "create_time"
    t.string "danger_yn_cd", limit: 1, default: "N", null: false
    t.string "goodsnm_cd", limit: 20, null: false
    t.string "if_yn_cd", limit: 1, default: "N", null: false
    t.string "item_cd", limit: 20, null: false
    t.string "item_nm", limit: 200, null: false
    t.string "len_unit_cd", limit: 20
    t.string "mdfr_nm_cd", limit: 50, null: false
    t.string "mstair_lading_yn_cd", limit: 1, default: "N", null: false
    t.decimal "net_wgt_kg", precision: 18, scale: 3
    t.decimal "pckg_qty", precision: 18, scale: 3
    t.string "png_yn_cd", limit: 1, default: "N", null: false
    t.string "prod_nm_cd", limit: 100, null: false
    t.string "qty_unit_cd", limit: 20
    t.datetime "reg_date", null: false
    t.string "regr_nm_cd", limit: 50, null: false
    t.string "tmpt_unit_cd", limit: 20
    t.decimal "tot_wgt_kg", precision: 18, scale: 3
    t.string "update_by", limit: 50
    t.datetime "update_time"
    t.string "use_yn_cd", limit: 1, default: "Y", null: false
    t.decimal "vessel_hght_m", precision: 18, scale: 3
    t.decimal "vessel_tmpt_c", precision: 18, scale: 3
    t.decimal "vessel_vert_m", precision: 18, scale: 3
    t.decimal "vessel_vol_cbm", precision: 18, scale: 3
    t.decimal "vessel_width_m", precision: 18, scale: 3
    t.string "vol_unit_cd", limit: 20
    t.string "wgt_unit_cd", limit: 20
    t.index ["bzac_cd", "item_cd"], name: "index_std_client_item_codes_on_bzac_cd_and_item_cd", unique: true
    t.index ["goodsnm_cd"], name: "index_std_client_item_codes_on_goodsnm_cd"
    t.index ["use_yn_cd"], name: "index_std_client_item_codes_on_use_yn_cd"
  end

  create_table "std_cm04004", force: :cascade do |t|
    t.text "after_value"
    t.text "before_value"
    t.string "bzac_cd", limit: 20, null: false
    t.datetime "changed_at"
    t.string "changed_by", limit: 50
    t.string "changed_col_nm", limit: 100, null: false
    t.string "create_by", limit: 50
    t.datetime "create_time"
    t.integer "hist_seq", null: false
    t.string "update_by", limit: 50
    t.datetime "update_time"
    t.index ["bzac_cd", "changed_at"], name: "index_std_cm04004_on_bzac_cd_and_changed_at"
    t.index ["bzac_cd", "hist_seq"], name: "index_std_cm04004_on_bzac_cd_and_hist_seq", unique: true
  end

  create_table "std_corporation_countries", force: :cascade do |t|
    t.string "aply_mon_unit_cd", limit: 20
    t.string "corp_cd", limit: 20, null: false
    t.string "create_by", limit: 50
    t.datetime "create_time"
    t.string "ctry_cd", limit: 10, null: false
    t.string "rpt_yn_cd", limit: 1, default: "N", null: false
    t.integer "seq", null: false
    t.string "std_time", limit: 40
    t.string "summer_time", limit: 40
    t.string "sys_lang_slc", limit: 20
    t.string "timezone_cd", limit: 60
    t.string "update_by", limit: 50
    t.datetime "update_time"
    t.string "use_yn_cd", limit: 1, default: "Y", null: false
    t.decimal "vat_rt", precision: 10, scale: 3
    t.index ["corp_cd", "ctry_cd"], name: "index_std_corporation_countries_on_corp_cd_and_ctry_cd"
    t.index ["corp_cd", "seq"], name: "index_std_corporation_countries_on_corp_cd_and_seq", unique: true
    t.index ["use_yn_cd"], name: "index_std_corporation_countries_on_use_yn_cd"
  end

  create_table "std_corporation_histories", force: :cascade do |t|
    t.text "after_value"
    t.text "before_value"
    t.datetime "changed_at"
    t.string "changed_by", limit: 50
    t.string "changed_col_nm", limit: 120, null: false
    t.string "corp_cd", limit: 20, null: false
    t.string "create_by", limit: 50
    t.datetime "create_time"
    t.integer "hist_seq", null: false
    t.string "source_key", limit: 120
    t.string "source_kind", limit: 20, null: false
    t.string "update_by", limit: 50
    t.datetime "update_time"
    t.index ["corp_cd", "changed_at"], name: "index_std_corp_hist_on_corp_and_changed_at"
    t.index ["corp_cd", "hist_seq"], name: "index_std_corp_hist_on_corp_and_seq", unique: true
  end

  create_table "std_corporations", force: :cascade do |t|
    t.string "addr_cd", limit: 300
    t.string "bizcond_cd", limit: 120, null: false
    t.string "compreg_slip_cd", limit: 30
    t.string "corp_cd", limit: 20, null: false
    t.string "corp_nm", limit: 120, null: false
    t.string "create_by", limit: 50
    t.datetime "create_time"
    t.string "dtl_addr_cd", limit: 300
    t.string "indstype_cd", limit: 120, null: false
    t.string "rptr_nm_cd", limit: 120, null: false
    t.string "update_by", limit: 50
    t.datetime "update_time"
    t.string "upper_corp_cd", limit: 20
    t.string "use_yn_cd", limit: 1, default: "Y", null: false
    t.string "vat_sctn_cd", limit: 30
    t.string "zip_cd", limit: 20
    t.index ["corp_cd"], name: "index_std_corporations_on_corp_cd", unique: true
    t.index ["corp_nm"], name: "index_std_corporations_on_corp_nm"
    t.index ["use_yn_cd"], name: "index_std_corporations_on_use_yn_cd"
  end

  create_table "std_countries", force: :cascade do |t|
    t.string "corp_cd", limit: 20
    t.string "corp_nm", limit: 120
    t.string "create_by", limit: 50
    t.datetime "create_time"
    t.string "ctry_ar_cd", limit: 30, null: false
    t.string "ctry_cd", limit: 10, null: false
    t.string "ctry_eng_nm", limit: 120, null: false
    t.string "ctry_nm", limit: 120, null: false
    t.string "ctry_telno", limit: 20
    t.string "update_by", limit: 50
    t.datetime "update_time"
    t.string "use_yn_cd", limit: 1, default: "Y", null: false
    t.index ["ctry_cd"], name: "index_std_countries_on_ctry_cd", unique: true
    t.index ["ctry_nm"], name: "index_std_countries_on_ctry_nm"
    t.index ["use_yn_cd"], name: "index_std_countries_on_use_yn_cd"
  end

  create_table "std_exchange_rates", force: :cascade do |t|
    t.string "anno_dgrcnt", limit: 20, null: false
    t.decimal "cash_buy", precision: 18, scale: 6
    t.decimal "cash_sell", precision: 18, scale: 6
    t.decimal "convmoney_rt", precision: 18, scale: 6
    t.string "create_by", limit: 50
    t.datetime "create_time"
    t.string "ctry_cd", limit: 10, null: false
    t.decimal "fcur_check_sell", precision: 18, scale: 6
    t.string "fnc_or_cd", limit: 20, null: false
    t.string "if_yn_cd", limit: 1, default: "N", null: false
    t.string "mon_cd", limit: 20, null: false
    t.decimal "sendmoney_rcvng", precision: 18, scale: 6
    t.decimal "sendmoney_sndg", precision: 18, scale: 6
    t.date "std_ymd", null: false
    t.decimal "tc_buy", precision: 18, scale: 6
    t.decimal "tradg_std_rt", precision: 18, scale: 6
    t.string "update_by", limit: 50
    t.datetime "update_time"
    t.decimal "usd_conv_rt", precision: 18, scale: 6
    t.string "use_yn_cd", limit: 1, default: "Y", null: false
    t.index ["ctry_cd", "fnc_or_cd", "std_ymd", "anno_dgrcnt", "mon_cd"], name: "index_std_exch_rate_business_key", unique: true
    t.index ["ctry_cd", "std_ymd"], name: "index_std_exchange_rates_on_ctry_cd_and_std_ymd"
    t.index ["use_yn_cd"], name: "index_std_exchange_rates_on_use_yn_cd"
  end

  create_table "std_financial_institutions", force: :cascade do |t|
    t.string "create_by", limit: 50
    t.datetime "create_time"
    t.string "ctry_cd", limit: 10
    t.string "ctry_nm", limit: 120
    t.string "fnc_or_cd", limit: 20, null: false
    t.string "fnc_or_eng_nm", limit: 120, null: false
    t.string "fnc_or_nm", limit: 120, null: false
    t.string "update_by", limit: 50
    t.datetime "update_time"
    t.string "use_yn_cd", limit: 1, default: "Y", null: false
    t.index ["ctry_cd"], name: "index_std_financial_institutions_on_ctry_cd"
    t.index ["fnc_or_cd"], name: "index_std_financial_institutions_on_fnc_or_cd", unique: true
    t.index ["fnc_or_nm"], name: "index_std_financial_institutions_on_fnc_or_nm"
    t.index ["use_yn_cd"], name: "index_std_financial_institutions_on_use_yn_cd"
  end

  create_table "std_goods", force: :cascade do |t|
    t.string "create_by", limit: 50
    t.datetime "create_time"
    t.string "goods_cd", limit: 20, null: false
    t.string "goods_nm", limit: 200, null: false
    t.string "hatae_cd", limit: 30
    t.string "hwajong_cd", limit: 30
    t.string "hwajong_grp_cd", limit: 30
    t.string "item_cd", limit: 30
    t.string "item_grp_cd", limit: 30
    t.string "rmk_cd", limit: 500
    t.string "update_by", limit: 50
    t.datetime "update_time"
    t.string "use_yn_cd", limit: 1, default: "Y", null: false
    t.index ["goods_cd"], name: "index_std_goods_on_goods_cd", unique: true
    t.index ["goods_nm"], name: "index_std_goods_on_goods_nm"
    t.index ["use_yn_cd"], name: "index_std_goods_on_use_yn_cd"
  end

  create_table "std_holidays", force: :cascade do |t|
    t.string "asmt_holday_yn_cd", limit: 1, default: "N", null: false
    t.string "clsdy_yn_cd", limit: 1, default: "N", null: false
    t.string "create_by", limit: 50
    t.datetime "create_time"
    t.string "ctry_cd", limit: 10, null: false
    t.string "event_day_yn_cd", limit: 1, default: "N", null: false
    t.string "holiday_nm_cd", limit: 120, null: false
    t.string "rmk_cd", limit: 500
    t.string "sat_yn_cd", limit: 1, default: "N", null: false
    t.string "sunday_yn_cd", limit: 1, default: "N", null: false
    t.string "update_by", limit: 50
    t.datetime "update_time"
    t.string "use_yn_cd", limit: 1, default: "Y", null: false
    t.date "ymd", null: false
    t.index ["ctry_cd", "ymd"], name: "index_std_holidays_on_ctry_cd_and_ymd", unique: true
    t.index ["use_yn_cd"], name: "index_std_holidays_on_use_yn_cd"
    t.index ["ymd"], name: "index_std_holidays_on_ymd"
  end

  create_table "std_interface_infos", force: :cascade do |t|
    t.string "bzac_nm", limit: 200
    t.string "bzac_sys_nm_cd", limit: 150
    t.string "corp_cd", limit: 20, null: false
    t.string "create_by", limit: 50
    t.datetime "create_time"
    t.string "if_bzac_cd", limit: 20
    t.string "if_cd", limit: 11, null: false
    t.text "if_desc_cd"
    t.string "if_meth_cd", limit: 30, null: false
    t.string "if_nm_cd", limit: 150, null: false
    t.string "if_sctn_cd", limit: 30, null: false
    t.string "rcv_sctn_cd", limit: 30
    t.string "rcv_sys_cd", limit: 30
    t.string "send_sys_cd", limit: 30
    t.string "update_by", limit: 50
    t.datetime "update_time"
    t.string "use_yn_cd", limit: 1, default: "Y", null: false
    t.index ["corp_cd", "if_nm_cd"], name: "index_std_interface_infos_on_corp_cd_and_if_nm_cd"
    t.index ["if_cd"], name: "index_std_interface_infos_on_if_cd", unique: true
    t.index ["use_yn_cd"], name: "index_std_interface_infos_on_use_yn_cd"
  end

  create_table "std_purchase_contract_change_histories", force: :cascade do |t|
    t.text "chg_aft_conts"
    t.text "chg_bef_conts"
    t.string "chg_col_nm", limit: 100, null: false
    t.datetime "chg_date"
    t.string "chg_tbl_nm", limit: 100, null: false
    t.string "create_by", limit: 50
    t.datetime "create_time"
    t.integer "purchase_contract_id", null: false
    t.string "regr_cd", limit: 50
    t.integer "seq_no", null: false
    t.string "update_by", limit: 50
    t.datetime "update_time"
    t.index ["purchase_contract_id", "chg_date"], name: "index_std_pur_ctrt_hist_on_contract_and_date"
    t.index ["purchase_contract_id", "seq_no"], name: "index_std_pur_ctrt_hist_on_contract_and_seq", unique: true
    t.index ["purchase_contract_id"], name: "idx_on_purchase_contract_id_e4345b7850"
  end

  create_table "std_purchase_contract_settlements", force: :cascade do |t|
    t.string "acnt_no_cd", limit: 50
    t.string "anno_dgrcnt", limit: 20
    t.string "aply_fnc_or_cd", limit: 50
    t.string "aply_fnc_or_nm", limit: 120
    t.string "create_by", limit: 50
    t.datetime "create_time"
    t.string "dpstr_nm", limit: 120
    t.string "exca_ofcr_cd", limit: 50
    t.string "exca_ofcr_nm", limit: 100
    t.string "exrt_aply_std_cd", limit: 30
    t.string "fnc_or_cd", limit: 50
    t.string "fnc_or_nm", limit: 120
    t.string "mon_cd", limit: 10
    t.decimal "prvs_cyfd_amt", precision: 18, scale: 2
    t.integer "purchase_contract_id", null: false
    t.text "remk"
    t.integer "seq_no", null: false
    t.string "update_by", limit: 50
    t.datetime "update_time"
    t.string "use_yn_cd", limit: 1, default: "Y", null: false
    t.index ["purchase_contract_id", "seq_no"], name: "index_std_pur_ctrt_stlmnt_on_contract_and_seq", unique: true
    t.index ["purchase_contract_id"], name: "idx_on_purchase_contract_id_3e0fa986e1"
    t.index ["use_yn_cd"], name: "index_std_purchase_contract_settlements_on_use_yn_cd"
  end

  create_table "std_purchase_contracts", force: :cascade do |t|
    t.string "apv_mthd_cd", limit: 30
    t.string "apv_type_cd", limit: 30
    t.string "bef_ctrt_no", limit: 30
    t.string "bilg_mthd_cd", limit: 30
    t.string "bizman_no", limit: 20, null: false
    t.string "bzac_cd", limit: 20, null: false
    t.string "bzac_sctn_cd", limit: 30
    t.string "corp_cd", limit: 20
    t.string "cprtco_ofcr_cd", limit: 50
    t.string "create_by", limit: 50
    t.datetime "create_time"
    t.string "ctrt_chg_reason_cd", limit: 255
    t.string "ctrt_cnctr_cond_cd", limit: 255
    t.string "ctrt_cnctr_dtl_reason_cd", limit: 500
    t.string "ctrt_cnctr_reason_cd", limit: 30
    t.date "ctrt_cnctr_ymd"
    t.string "ctrt_dept_cd", limit: 50
    t.string "ctrt_dept_nm", limit: 100
    t.date "ctrt_end_day"
    t.date "ctrt_expi_noti_ymd"
    t.date "ctrt_exten_ymd"
    t.string "ctrt_kind_cd", limit: 30, null: false
    t.string "ctrt_ofcr_cd", limit: 50
    t.string "ctrt_ofcr_nm", limit: 100
    t.string "ctrt_sctn_cd", limit: 30, null: false
    t.date "ctrt_strt_day"
    t.string "dcsn_yn_cd", limit: 1, default: "N", null: false
    t.string "loan_limt_over_yn_cd", limit: 1, default: "N", null: false
    t.string "op_area_cd", limit: 100
    t.string "pay_cond_cd", limit: 30
    t.string "pur_ctrt_nm", limit: 200, null: false
    t.string "pur_ctrt_no", limit: 30, null: false
    t.string "re_ctrt_cond_cd", limit: 255
    t.text "remk"
    t.date "strt_ctrt_ymd"
    t.string "update_by", limit: 50
    t.datetime "update_time"
    t.string "use_yn_cd", limit: 1, default: "Y", null: false
    t.string "vat_sctn_cd", limit: 30
    t.string "work_step_no1_cd", limit: 30
    t.string "work_step_no2_cd", limit: 30
    t.index ["bzac_cd"], name: "index_std_purchase_contracts_on_bzac_cd"
    t.index ["corp_cd"], name: "index_std_purchase_contracts_on_corp_cd"
    t.index ["ctrt_sctn_cd"], name: "index_std_purchase_contracts_on_ctrt_sctn_cd"
    t.index ["ctrt_strt_day"], name: "index_std_purchase_contracts_on_ctrt_strt_day"
    t.index ["pur_ctrt_no"], name: "index_std_purchase_contracts_on_pur_ctrt_no", unique: true
    t.index ["use_yn_cd"], name: "index_std_purchase_contracts_on_use_yn_cd"
  end

  create_table "std_region_zip_mappings", force: :cascade do |t|
    t.string "create_by", limit: 50
    t.datetime "create_time"
    t.string "ctry_cd", limit: 10, null: false
    t.string "regn_cd", limit: 10, null: false
    t.integer "seq_no", default: 1, null: false
    t.integer "sort_seq", default: 0, null: false
    t.string "update_by", limit: 50
    t.datetime "update_time"
    t.string "zipcd", limit: 20, null: false
    t.index ["regn_cd", "ctry_cd", "zipcd", "seq_no"], name: "index_std_region_zip_map_unique", unique: true
    t.index ["regn_cd", "sort_seq"], name: "index_std_region_zip_map_on_regn_and_sort"
  end

  create_table "std_regions", force: :cascade do |t|
    t.string "corp_cd", limit: 20, null: false
    t.string "create_by", limit: 50
    t.datetime "create_time"
    t.string "regn_cd", limit: 10, null: false
    t.string "regn_eng_nm_cd", limit: 120, null: false
    t.string "regn_nm_cd", limit: 120, null: false
    t.string "rmk_cd", limit: 500
    t.string "update_by", limit: 50
    t.datetime "update_time"
    t.string "upper_regn_cd", limit: 10
    t.string "use_yn_cd", limit: 1, default: "Y", null: false
    t.index ["corp_cd"], name: "index_std_regions_on_corp_cd"
    t.index ["regn_cd"], name: "index_std_regions_on_regn_cd", unique: true
    t.index ["regn_nm_cd"], name: "index_std_regions_on_regn_nm_cd"
    t.index ["use_yn_cd"], name: "index_std_regions_on_use_yn_cd"
  end

  create_table "std_reserved_jobs", force: :cascade do |t|
    t.string "create_by", limit: 50
    t.datetime "create_time"
    t.integer "hms_unit_min"
    t.string "pgm_sctn_cd", limit: 30
    t.string "rel_menu_cd", limit: 20
    t.string "rel_menu_nm", limit: 150
    t.string "rel_pgm_cd", limit: 60
    t.string "rel_pgm_nm", limit: 150
    t.text "rmk_cd"
    t.string "rsv_work_cycle_cd", limit: 30, null: false
    t.string "rsv_work_desc_cd", limit: 300, null: false
    t.string "rsv_work_nm_cd", limit: 150, null: false
    t.string "rsv_work_no", limit: 20, null: false
    t.string "sys_sctn_cd", limit: 30, null: false
    t.string "update_by", limit: 50
    t.datetime "update_time"
    t.string "use_yn_cd", limit: 1, default: "Y", null: false
    t.index ["rsv_work_no"], name: "index_std_reserved_jobs_on_rsv_work_no", unique: true
    t.index ["sys_sctn_cd", "rsv_work_nm_cd"], name: "index_std_reserved_jobs_on_sys_sctn_cd_and_rsv_work_nm_cd"
    t.index ["use_yn_cd"], name: "index_std_reserved_jobs_on_use_yn_cd"
  end

  create_table "std_sell_contract_change_histories", force: :cascade do |t|
    t.text "chg_aft_conts"
    t.text "chg_bef_conts"
    t.string "chg_col_nm", limit: 100, null: false
    t.datetime "chg_date"
    t.string "chg_tbl_nm", limit: 100, null: false
    t.string "create_by", limit: 50
    t.datetime "create_time"
    t.string "regr_cd", limit: 50
    t.integer "sell_contract_id", null: false
    t.integer "seq_no", null: false
    t.string "update_by", limit: 50
    t.datetime "update_time"
    t.index ["sell_contract_id", "chg_date"], name: "index_std_sell_ctrt_hist_on_contract_and_date"
    t.index ["sell_contract_id", "seq_no"], name: "index_std_sell_ctrt_hist_on_contract_and_seq", unique: true
    t.index ["sell_contract_id"], name: "index_std_sell_contract_change_histories_on_sell_contract_id"
  end

  create_table "std_sell_contract_settlements", force: :cascade do |t|
    t.string "acnt_no_cd", limit: 50
    t.string "anno_dgrcnt", limit: 20
    t.string "aply_fnc_or_cd", limit: 50
    t.string "aply_fnc_or_nm", limit: 120
    t.string "create_by", limit: 50
    t.datetime "create_time"
    t.string "dpstr_nm", limit: 120
    t.string "exca_ofcr_cd", limit: 50
    t.string "exca_ofcr_nm", limit: 100
    t.string "exrt_aply_std_cd", limit: 30
    t.string "fnc_or_cd", limit: 50
    t.string "fnc_or_nm", limit: 120
    t.string "main_bank_yn_cd", limit: 1
    t.string "mon_cd", limit: 10
    t.decimal "prvs_cyfd_amt", precision: 18, scale: 2
    t.text "remk"
    t.integer "sell_contract_id", null: false
    t.integer "seq_no", null: false
    t.string "update_by", limit: 50
    t.datetime "update_time"
    t.string "use_yn_cd", limit: 1, default: "Y", null: false
    t.index ["sell_contract_id", "seq_no"], name: "index_std_sell_ctrt_stlmnt_on_contract_and_seq", unique: true
    t.index ["sell_contract_id"], name: "index_std_sell_contract_settlements_on_sell_contract_id"
    t.index ["use_yn_cd"], name: "index_std_sell_contract_settlements_on_use_yn_cd"
  end

  create_table "std_sell_contracts", force: :cascade do |t|
    t.string "apv_mthd_cd", limit: 30
    t.string "apv_type_cd", limit: 30
    t.string "bef_ctrt_no", limit: 30
    t.string "bilg_mthd_cd", limit: 30
    t.string "bizman_no", limit: 20, null: false
    t.string "bzac_cd", limit: 20, null: false
    t.decimal "contrbtn_bnfit_amt", precision: 18, scale: 2
    t.decimal "contrbtn_bnfit_rt", precision: 8, scale: 4
    t.string "corp_cd", limit: 20
    t.string "create_by", limit: 50
    t.datetime "create_time"
    t.decimal "ctrt_amt", precision: 18, scale: 2
    t.string "ctrt_amt_chg_reason", limit: 255
    t.string "ctrt_cnctr_cond", limit: 255
    t.string "ctrt_cnctr_dtl_reason", limit: 500
    t.string "ctrt_cnctr_reason_cd", limit: 30
    t.date "ctrt_cnctr_ymd"
    t.string "ctrt_dept_cd", limit: 50
    t.string "ctrt_dept_nm", limit: 100
    t.date "ctrt_end_day"
    t.date "ctrt_expi_noti_ymd"
    t.date "ctrt_exten_ymd"
    t.string "ctrt_kind_cd", limit: 30, null: false
    t.string "ctrt_sctn_cd", limit: 30, null: false
    t.date "ctrt_strt_day"
    t.string "dcsn_yn_cd", limit: 1, default: "N", null: false
    t.string "indgrp_cd", limit: 30
    t.string "loan_limt_over_yn_cd", limit: 1, default: "N", null: false
    t.string "main_rsbt_clause", limit: 500
    t.date "ord_recp_poss_ymd"
    t.string "re_ctrt_cond", limit: 255
    t.text "remk"
    t.decimal "sell_bnfit_amt", precision: 18, scale: 2
    t.decimal "sell_bnfit_rt", precision: 8, scale: 4
    t.string "sell_ctrt_nm", limit: 200, null: false
    t.string "sell_ctrt_no", limit: 30, null: false
    t.date "strt_ctrt_ymd"
    t.string "update_by", limit: 50
    t.datetime "update_time"
    t.string "use_yn_cd", limit: 1, default: "Y", null: false
    t.string "vat_sctn_cd", limit: 30
    t.index ["bzac_cd"], name: "index_std_sell_contracts_on_bzac_cd"
    t.index ["corp_cd"], name: "index_std_sell_contracts_on_corp_cd"
    t.index ["ctrt_sctn_cd"], name: "index_std_sell_contracts_on_ctrt_sctn_cd"
    t.index ["ctrt_strt_day"], name: "index_std_sell_contracts_on_ctrt_strt_day"
    t.index ["sell_ctrt_no"], name: "index_std_sell_contracts_on_sell_ctrt_no", unique: true
    t.index ["use_yn_cd"], name: "index_std_sell_contracts_on_use_yn_cd"
  end

  create_table "std_sellbuy_attributes", force: :cascade do |t|
    t.string "cgwrk_yn_cd", limit: 1, default: "N", null: false
    t.string "corp_cd", limit: 20, null: false
    t.string "create_by", limit: 50
    t.datetime "create_time"
    t.string "dc_extr_yn_cd", limit: 1, default: "N", null: false
    t.string "dcnct_reg_pms_yn_cd", limit: 1, default: "N", null: false
    t.string "fis_air_yn_cd", limit: 1, default: "N", null: false
    t.string "fis_shpng_yn_cd", limit: 1, default: "N", null: false
    t.string "lumpsum_yn_cd", limit: 1, default: "N", null: false
    t.string "ndcsn_cost_dr_acct_cd", limit: 30
    t.string "ndcsn_sell_cr_acct_cd", limit: 30
    t.string "pur_cr_acct_cd", limit: 30
    t.string "pur_dr_acct_cd", limit: 30
    t.string "pur_yn_cd", limit: 1, default: "N", null: false
    t.string "rdtn_nm", limit: 120, null: false
    t.string "rmk_cd", limit: 500
    t.string "sell_cr_acct_cd", limit: 30
    t.string "sell_dr_acct_cd", limit: 30
    t.string "sell_yn_cd", limit: 1, default: "N", null: false
    t.string "sellbuy_attr_cd", limit: 20, null: false
    t.string "sellbuy_attr_eng_nm", limit: 150, null: false
    t.string "sellbuy_attr_nm", limit: 150, null: false
    t.string "sellbuy_sctn_cd", limit: 30
    t.string "strg_yn_cd", limit: 1, default: "N", null: false
    t.string "sys_sctn_cd", limit: 30
    t.string "tax_payfor_yn_cd", limit: 1, default: "N", null: false
    t.string "tran_yn_cd", limit: 1, default: "N", null: false
    t.string "update_by", limit: 50
    t.datetime "update_time"
    t.string "upper_sellbuy_attr_cd", limit: 20
    t.string "use_yn_cd", limit: 1, default: "Y", null: false
    t.index ["corp_cd"], name: "index_std_sellbuy_attributes_on_corp_cd"
    t.index ["sellbuy_attr_cd"], name: "index_std_sellbuy_attributes_on_sellbuy_attr_cd", unique: true
    t.index ["use_yn_cd"], name: "index_std_sellbuy_attributes_on_use_yn_cd"
  end

  create_table "std_user_favorite_groups", force: :cascade do |t|
    t.string "create_by", limit: 50
    t.datetime "create_time"
    t.string "group_nm", limit: 100, null: false
    t.string "update_by", limit: 50
    t.datetime "update_time"
    t.string "use_yn", limit: 1, default: "Y", null: false
    t.string "user_id_code", limit: 16, null: false
    t.index ["use_yn"], name: "index_std_user_favorite_groups_on_use_yn"
    t.index ["user_id_code", "group_nm"], name: "index_std_favor_groups_on_user_and_name", unique: true
  end

  create_table "std_user_favorites", force: :cascade do |t|
    t.string "create_by", limit: 50
    t.datetime "create_time"
    t.string "menu_cd", limit: 20, null: false
    t.string "menu_nm", limit: 100
    t.integer "sort_seq", default: 0, null: false
    t.string "update_by", limit: 50
    t.datetime "update_time"
    t.string "use_yn", limit: 1, default: "Y", null: false
    t.string "user_favor_menu_grp", limit: 100
    t.string "user_id_code", limit: 16, null: false
    t.index ["use_yn"], name: "index_std_user_favorites_on_use_yn"
    t.index ["user_id_code", "menu_cd"], name: "index_std_favorites_on_user_and_menu", unique: true
    t.index ["user_id_code", "user_favor_menu_grp"], name: "index_std_favorites_on_user_and_group"
  end

  create_table "std_workplaces", force: :cascade do |t|
    t.string "addr_cd", limit: 300
    t.decimal "adpt_capa", precision: 14, scale: 3
    t.string "bzac_cd", limit: 20
    t.string "capa_spec_unit_cd", limit: 30
    t.string "corp_cd", limit: 20, null: false
    t.string "create_by", limit: 50
    t.datetime "create_time"
    t.string "ctry_cd", limit: 10
    t.string "dept_cd", limit: 50, null: false
    t.decimal "dimem", precision: 14, scale: 3
    t.string "dimem_spec_unit_cd", limit: 30
    t.string "dtl_addr_cd", limit: 300
    t.decimal "max_capa", precision: 14, scale: 3
    t.text "remk_cd"
    t.string "update_by", limit: 50
    t.datetime "update_time"
    t.string "upper_workpl_cd", limit: 20
    t.string "use_yn_cd", limit: 1, default: "Y", null: false
    t.string "wm_yn_cd", limit: 1, default: "N", null: false
    t.string "workpl_cd", limit: 20, null: false
    t.string "workpl_nm", limit: 120, null: false
    t.string "workpl_sctn_cd", limit: 50, null: false
    t.string "zip_cd", limit: 20
    t.index ["corp_cd"], name: "index_std_workplaces_on_corp_cd"
    t.index ["use_yn_cd"], name: "index_std_workplaces_on_use_yn_cd"
    t.index ["workpl_cd"], name: "index_std_workplaces_on_workpl_cd", unique: true
    t.index ["workpl_nm"], name: "index_std_workplaces_on_workpl_nm"
  end

  create_table "std_zip_codes", force: :cascade do |t|
    t.string "create_by", limit: 50
    t.datetime "create_time"
    t.string "ctry_cd", limit: 10, null: false
    t.string "eupdiv", limit: 80
    t.integer "seq_no", default: 1, null: false
    t.string "sgng", limit: 80
    t.string "sido", limit: 80
    t.string "update_by", limit: 50
    t.datetime "update_time"
    t.string "use_yn_cd", limit: 1, default: "Y", null: false
    t.string "zipaddr", limit: 300
    t.string "zipcd", limit: 20, null: false
    t.index ["ctry_cd", "zipcd", "seq_no"], name: "index_std_zip_codes_on_ctry_cd_and_zipcd_and_seq_no", unique: true
    t.index ["use_yn_cd"], name: "index_std_zip_codes_on_use_yn_cd"
    t.index ["zipcd"], name: "index_std_zip_codes_on_zipcd"
  end

  create_table "tb_wm02001", id: false, force: :cascade do |t|
    t.string "car_no", limit: 20
    t.string "corp_cd", limit: 10, null: false
    t.string "create_by", limit: 50
    t.datetime "create_time"
    t.string "cust_cd", limit: 20, null: false
    t.string "dptar_cd", limit: 20
    t.string "dptar_type_cd", limit: 10
    t.string "driver_nm", limit: 50
    t.string "driver_telno", limit: 20
    t.string "exec_ord_no", limit: 30
    t.string "gr_hms", limit: 6
    t.string "gr_prar_no", limit: 20, null: false
    t.string "gr_stat_cd", limit: 10, default: "10", null: false
    t.string "gr_type_cd", limit: 10
    t.string "gr_ymd", limit: 8
    t.string "ord_no", limit: 30
    t.string "ord_reason_cd", limit: 10
    t.string "prar_ymd", limit: 8
    t.string "rel_gi_ord_no", limit: 30
    t.string "rmk", limit: 500
    t.string "transco_cd", limit: 20
    t.string "update_by", limit: 50
    t.datetime "update_time"
    t.string "workpl_cd", limit: 20, null: false
    t.index ["cust_cd"], name: "index_tb_wm02001_on_cust_cd"
    t.index ["gr_stat_cd"], name: "index_tb_wm02001_on_gr_stat_cd"
    t.index ["gr_ymd"], name: "index_tb_wm02001_on_gr_ymd"
    t.index ["prar_ymd"], name: "index_tb_wm02001_on_prar_ymd"
    t.index ["workpl_cd"], name: "index_tb_wm02001_on_workpl_cd"
  end

  create_table "tb_wm02002", id: false, force: :cascade do |t|
    t.string "create_by", limit: 50
    t.datetime "create_time"
    t.string "gr_hms", limit: 6
    t.string "gr_loc_cd", limit: 20
    t.string "gr_prar_no", limit: 20, null: false
    t.decimal "gr_prar_qty", precision: 18, scale: 3
    t.decimal "gr_qty", precision: 18, scale: 3, default: "0.0"
    t.decimal "gr_rslt_qty", precision: 18, scale: 3, default: "0.0"
    t.string "gr_stat_cd", limit: 10, default: "10"
    t.string "gr_ymd", limit: 8
    t.string "item_cd", limit: 30, null: false
    t.string "item_nm", limit: 200
    t.integer "lineno", null: false
    t.string "rmk", limit: 500
    t.string "stock_attr_col01", limit: 100
    t.string "stock_attr_col02", limit: 100
    t.string "stock_attr_col03", limit: 100
    t.string "stock_attr_col04", limit: 100
    t.string "stock_attr_col05", limit: 100
    t.string "stock_attr_col06", limit: 100
    t.string "stock_attr_col07", limit: 100
    t.string "stock_attr_col08", limit: 100
    t.string "stock_attr_col09", limit: 100
    t.string "stock_attr_col10", limit: 100
    t.string "unit_cd", limit: 10
    t.string "update_by", limit: 50
    t.datetime "update_time"
    t.index ["gr_stat_cd"], name: "index_tb_wm02002_on_gr_stat_cd"
    t.index ["item_cd"], name: "index_tb_wm02002_on_item_cd"
  end

  create_table "tb_wm04001", id: false, force: :cascade do |t|
    t.string "corp_cd", limit: 10, null: false
    t.string "create_by", limit: 50
    t.datetime "create_time"
    t.string "cust_cd", limit: 20, null: false
    t.string "item_cd", limit: 30, null: false
    t.string "stock_attr_col01", limit: 100
    t.string "stock_attr_col02", limit: 100
    t.string "stock_attr_col03", limit: 100
    t.string "stock_attr_col04", limit: 100
    t.string "stock_attr_col05", limit: 100
    t.string "stock_attr_col06", limit: 100
    t.string "stock_attr_col07", limit: 100
    t.string "stock_attr_col08", limit: 100
    t.string "stock_attr_col09", limit: 100
    t.string "stock_attr_col10", limit: 100
    t.string "stock_attr_no", limit: 10, null: false
    t.string "update_by", limit: 50
    t.datetime "update_time"
    t.index ["corp_cd", "cust_cd", "item_cd"], name: "idx_wm04001_corp_cust_item"
  end

  create_table "tb_wm04002", id: false, force: :cascade do |t|
    t.decimal "alloc_qty", precision: 18, scale: 3, default: "0.0", null: false
    t.string "basis_unit_cd", limit: 10
    t.string "basis_unit_cls", limit: 10
    t.string "corp_cd", limit: 10, null: false
    t.string "create_by", limit: 50
    t.datetime "create_time"
    t.string "cust_cd", limit: 20
    t.decimal "hold_qty", precision: 18, scale: 3, default: "0.0", null: false
    t.string "item_cd", limit: 30
    t.decimal "pick_qty", precision: 18, scale: 3, default: "0.0", null: false
    t.decimal "qty", precision: 18, scale: 3, default: "0.0", null: false
    t.string "stock_attr_no", limit: 10, null: false
    t.string "update_by", limit: 50
    t.datetime "update_time"
    t.string "workpl_cd", limit: 20, null: false
  end

  create_table "tb_wm04003", id: false, force: :cascade do |t|
    t.decimal "alloc_qty", precision: 18, scale: 3, default: "0.0", null: false
    t.string "basis_unit_cd", limit: 10
    t.string "basis_unit_cls", limit: 10
    t.string "corp_cd", limit: 10, null: false
    t.string "create_by", limit: 50
    t.datetime "create_time"
    t.string "cust_cd", limit: 20
    t.decimal "hold_qty", precision: 18, scale: 3, default: "0.0", null: false
    t.string "item_cd", limit: 30
    t.string "loc_cd", limit: 20, null: false
    t.decimal "pick_qty", precision: 18, scale: 3, default: "0.0", null: false
    t.decimal "qty", precision: 18, scale: 3, default: "0.0", null: false
    t.string "stock_attr_no", limit: 10, null: false
    t.string "update_by", limit: 50
    t.datetime "update_time"
    t.string "workpl_cd", limit: 20, null: false
  end

  create_table "tb_wm04004", id: false, force: :cascade do |t|
    t.decimal "alloc_qty", precision: 18, scale: 3, default: "0.0", null: false
    t.string "basis_unit_cd", limit: 10
    t.string "basis_unit_cls", limit: 10
    t.string "corp_cd", limit: 10, null: false
    t.string "create_by", limit: 50
    t.datetime "create_time"
    t.string "cust_cd", limit: 20, null: false
    t.decimal "hold_qty", precision: 18, scale: 3, default: "0.0", null: false
    t.string "item_cd", limit: 30, null: false
    t.string "loc_cd", limit: 20, null: false
    t.decimal "pick_qty", precision: 18, scale: 3, default: "0.0", null: false
    t.decimal "qty", precision: 18, scale: 3, default: "0.0", null: false
    t.string "update_by", limit: 50
    t.datetime "update_time"
    t.string "workpl_cd", limit: 20, null: false
  end

  create_table "tb_wm05001", id: false, force: :cascade do |t|
    t.string "basis_unit_cd", limit: 10
    t.string "basis_unit_cls", limit: 10
    t.string "corp_cd", limit: 10
    t.string "create_by", limit: 50
    t.datetime "create_time"
    t.string "cust_cd", limit: 20
    t.string "exce_rslt_hms", limit: 6
    t.string "exce_rslt_no", limit: 10, null: false
    t.string "exce_rslt_type", limit: 10
    t.string "exce_rslt_ymd", limit: 8
    t.string "exec_ord_no", limit: 30
    t.string "from_loc", limit: 20
    t.string "item_cd", limit: 30
    t.string "op_rslt_mngt_no", limit: 20
    t.integer "op_rslt_mngt_no_seq"
    t.string "ord_no", limit: 30
    t.decimal "rslt_cbm", precision: 18, scale: 5
    t.decimal "rslt_net_wt", precision: 18, scale: 5
    t.decimal "rslt_qty", precision: 18, scale: 3
    t.decimal "rslt_total_wt", precision: 18, scale: 5
    t.string "stock_attr_col01", limit: 100
    t.string "stock_attr_col02", limit: 100
    t.string "stock_attr_col03", limit: 100
    t.string "stock_attr_col04", limit: 100
    t.string "stock_attr_col05", limit: 100
    t.string "stock_attr_col06", limit: 100
    t.string "stock_attr_col07", limit: 100
    t.string "stock_attr_col08", limit: 100
    t.string "stock_attr_col09", limit: 100
    t.string "stock_attr_col10", limit: 100
    t.string "stock_attr_no", limit: 10
    t.string "to_loc", limit: 20
    t.string "update_by", limit: 50
    t.datetime "update_time"
    t.string "workpl_cd", limit: 20
    t.index ["exce_rslt_type"], name: "index_tb_wm05001_on_exce_rslt_type"
    t.index ["exce_rslt_ymd"], name: "index_tb_wm05001_on_exce_rslt_ymd"
    t.index ["op_rslt_mngt_no"], name: "index_tb_wm05001_on_op_rslt_mngt_no"
  end

  create_table "tb_wm06001", primary_key: "wrhs_exca_fee_rt_no", id: { type: :string, limit: 20 }, force: :cascade do |t|
    t.string "auto_yn", limit: 1, default: "N", null: false
    t.string "corp_cd", limit: 10, null: false
    t.string "create_by", limit: 50
    t.datetime "create_time"
    t.string "ctrt_cprtco_cd", limit: 20
    t.string "pur_dept_cd", limit: 20
    t.string "pur_item_cd", limit: 20
    t.string "pur_item_type", limit: 20
    t.string "pur_unit_cd", limit: 20
    t.string "pur_unit_clas_cd", limit: 20
    t.string "rmk", limit: 500
    t.string "sell_buy_attr_cd", limit: 20
    t.string "sell_buy_sctn_cd", limit: 10, default: "20", null: false
    t.string "update_by", limit: 50
    t.datetime "update_time"
    t.string "use_yn", limit: 1, default: "Y", null: false
    t.string "work_pl_cd", limit: 20, null: false
  end

  create_table "tb_wm06002", force: :cascade do |t|
    t.decimal "aply_end_qty", precision: 18, scale: 5
    t.string "aply_end_ymd", limit: 8, null: false
    t.decimal "aply_strt_qty", precision: 18, scale: 5
    t.string "aply_strt_ymd", limit: 8, null: false
    t.decimal "aply_uprice", precision: 18, scale: 5, default: "0.0", null: false
    t.string "create_by", limit: 50
    t.datetime "create_time"
    t.string "cur_cd", limit: 10, default: "KRW", null: false
    t.string "dcsn_yn", limit: 1, default: "N", null: false
    t.integer "lineno", default: 1, null: false
    t.string "rmk", limit: 500
    t.decimal "std_work_qty", precision: 18, scale: 5, default: "0.0", null: false
    t.string "update_by", limit: 50
    t.datetime "update_time"
    t.string "wrhs_exca_fee_rt_no", limit: 20, null: false
    t.index ["wrhs_exca_fee_rt_no", "lineno"], name: "idx_wm06002_rt_lineno"
  end

  create_table "wm_areas", force: :cascade do |t|
    t.string "area_cd", limit: 50, null: false
    t.string "area_desc", limit: 500
    t.string "area_nm", limit: 100, null: false
    t.string "create_by", limit: 50
    t.datetime "create_time"
    t.string "update_by", limit: 50
    t.datetime "update_time"
    t.string "use_yn", limit: 1, default: "Y", null: false
    t.string "workpl_cd", limit: 50, null: false
    t.index ["area_nm"], name: "index_wm_areas_on_area_nm"
    t.index ["use_yn"], name: "index_wm_areas_on_use_yn"
    t.index ["workpl_cd", "area_cd"], name: "index_wm_areas_on_workpl_cd_and_area_cd", unique: true
    t.index ["workpl_cd"], name: "index_wm_areas_on_workpl_cd"
  end

  create_table "wm_cust_rules", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "wm_cust_stock_attrs", force: :cascade do |t|
    t.string "attr_desc", limit: 500
    t.string "create_by", limit: 50
    t.datetime "create_time"
    t.string "cust_cd", limit: 50, null: false
    t.string "inout_sctn", limit: 50, null: false
    t.string "rel_col", limit: 50
    t.string "rel_tbl", limit: 50
    t.string "stock_attr_sctn", limit: 50, null: false
    t.string "update_by", limit: 50
    t.datetime "update_time"
    t.string "use_yn", limit: 1, default: "Y", null: false
    t.index ["cust_cd", "inout_sctn", "stock_attr_sctn"], name: "idx_wm_cust_stock_attrs_uk", unique: true
  end

  create_table "wm_customer_rules", force: :cascade do |t|
    t.string "aply_yn"
    t.datetime "created_at", null: false
    t.string "cust_cd"
    t.string "inout_sctn"
    t.string "inout_type"
    t.string "rmk"
    t.string "rule_sctn"
    t.datetime "updated_at", null: false
    t.string "workpl_cd"
  end

  create_table "wm_customer_stock_attributes", force: :cascade do |t|
    t.string "attr_desc", limit: 200
    t.string "corp_cd", limit: 20, null: false
    t.string "create_by", limit: 50
    t.datetime "create_time"
    t.datetime "created_at", null: false
    t.bigint "cust_id", null: false
    t.string "inout_sctn_cd", limit: 10, null: false
    t.string "rel_col_nm", limit: 50
    t.string "rel_tbl_nm", limit: 50
    t.string "stock_attr_sctn_cd", limit: 10, null: false
    t.string "update_by", limit: 50
    t.datetime "update_time"
    t.datetime "updated_at", null: false
    t.string "use_yn", limit: 1, default: "Y", null: false
    t.index ["corp_cd", "cust_id", "inout_sctn_cd", "stock_attr_sctn_cd"], name: "idx_wm_cust_stock_attr_unique", unique: true
  end

  create_table "wm_locations", force: :cascade do |t|
    t.string "area_cd", limit: 50, null: false
    t.string "create_by", limit: 50
    t.datetime "create_time"
    t.string "has_stock", limit: 1, default: "N", null: false
    t.decimal "height_len", precision: 12, scale: 3
    t.string "loc_cd", limit: 50, null: false
    t.string "loc_class_cd", limit: 30
    t.string "loc_nm", limit: 100, null: false
    t.string "loc_type_cd", limit: 30
    t.decimal "max_cbm", precision: 14, scale: 3
    t.decimal "max_weight", precision: 14, scale: 3
    t.string "update_by", limit: 50
    t.datetime "update_time"
    t.string "use_yn", limit: 1, default: "Y", null: false
    t.decimal "vert_len", precision: 12, scale: 3
    t.decimal "width_len", precision: 12, scale: 3
    t.string "workpl_cd", limit: 50, null: false
    t.string "zone_cd", limit: 50, null: false
    t.index ["has_stock"], name: "index_wm_locations_on_has_stock"
    t.index ["loc_nm"], name: "index_wm_locations_on_loc_nm"
    t.index ["use_yn"], name: "index_wm_locations_on_use_yn"
    t.index ["workpl_cd", "area_cd", "zone_cd", "loc_cd"], name: "idx_on_workpl_cd_area_cd_zone_cd_loc_cd_56a16d1b88", unique: true
    t.index ["workpl_cd", "area_cd", "zone_cd"], name: "index_wm_locations_on_workpl_cd_and_area_cd_and_zone_cd"
  end

  create_table "wm_workplaces", force: :cascade do |t|
    t.string "addr", limit: 300
    t.string "addr_dtl", limit: 300
    t.string "client_cd", limit: 50
    t.string "create_by", limit: 50
    t.datetime "create_time"
    t.string "fax_no", limit: 30
    t.string "nation_cd", limit: 20
    t.string "prop_cd", limit: 50
    t.text "remk"
    t.string "tel_no", limit: 30
    t.string "update_by", limit: 50
    t.datetime "update_time"
    t.string "use_yn", limit: 1, default: "Y", null: false
    t.string "workpl_cd", limit: 50, null: false
    t.string "workpl_nm", limit: 100, null: false
    t.string "workpl_type", limit: 50
    t.string "zip_cd", limit: 20
    t.index ["use_yn"], name: "index_wm_workplaces_on_use_yn"
    t.index ["workpl_cd"], name: "index_wm_workplaces_on_workpl_cd", unique: true
    t.index ["workpl_nm"], name: "index_wm_workplaces_on_workpl_nm"
    t.index ["workpl_type"], name: "index_wm_workplaces_on_workpl_type"
  end

  create_table "wm_zones", force: :cascade do |t|
    t.string "area_cd", limit: 50, null: false
    t.string "create_by", limit: 50
    t.datetime "create_time"
    t.string "update_by", limit: 50
    t.datetime "update_time"
    t.string "use_yn", limit: 1, default: "Y", null: false
    t.string "workpl_cd", limit: 50, null: false
    t.string "zone_cd", limit: 50, null: false
    t.string "zone_desc", limit: 500
    t.string "zone_nm", limit: 100, null: false
    t.index ["use_yn"], name: "index_wm_zones_on_use_yn"
    t.index ["workpl_cd", "area_cd", "zone_cd"], name: "index_wm_zones_on_workpl_cd_and_area_cd_and_zone_cd", unique: true
    t.index ["workpl_cd", "area_cd"], name: "index_wm_zones_on_workpl_cd_and_area_cd"
    t.index ["zone_nm"], name: "index_wm_zones_on_zone_nm"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "adm_user_menu_permissions", "adm_users", column: "user_id"
  add_foreign_key "adm_users", "adm_depts", column: "dept_id"
  add_foreign_key "adm_users", "adm_roles", column: "role_id"
  add_foreign_key "excel_import_tasks", "adm_users", column: "requested_by_id"
  add_foreign_key "om_internal_order_items", "om_internal_orders", column: "internal_order_id"
  add_foreign_key "sessions", "adm_users", column: "user_id"
  add_foreign_key "std_purchase_contract_change_histories", "std_purchase_contracts", column: "purchase_contract_id"
  add_foreign_key "std_purchase_contract_settlements", "std_purchase_contracts", column: "purchase_contract_id"
  add_foreign_key "std_sell_contract_change_histories", "std_sell_contracts", column: "sell_contract_id"
  add_foreign_key "std_sell_contract_settlements", "std_sell_contracts", column: "sell_contract_id"
end
