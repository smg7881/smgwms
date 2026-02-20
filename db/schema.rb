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

ActiveRecord::Schema[8.1].define(version: 2026_02_21_014000) do
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
    t.string "code", limit: 50, null: false
    t.string "create_by", limit: 50
    t.datetime "create_time"
    t.string "detail_code", limit: 50, null: false
    t.string "detail_code_name", limit: 100, null: false
    t.string "ref_code", limit: 50
    t.string "short_name", limit: 100
    t.integer "sort_order", default: 0, null: false
    t.string "update_by", limit: 50
    t.datetime "update_time"
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
  add_foreign_key "sessions", "adm_users", column: "user_id"
end
