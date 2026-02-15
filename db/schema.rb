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

ActiveRecord::Schema[8.1].define(version: 2026_02_15_120000) do
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

  create_table "adm_depts", id: false, force: :cascade do |t|
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

  create_table "adm_users", force: :cascade do |t|
    t.string "address"
    t.datetime "created_at", null: false
    t.string "dept_cd"
    t.string "dept_nm"
    t.string "detail_address"
    t.string "email_address"
    t.date "hire_date"
    t.string "job_title_cd"
    t.string "password_digest"
    t.string "phone"
    t.string "position_cd"
    t.date "resign_date"
    t.string "role_cd"
    t.datetime "updated_at", null: false
    t.string "user_id_code"
    t.string "user_nm"
    t.string "work_status", default: "ACTIVE"
    t.index ["user_id_code"], name: "index_adm_users_on_user_id_code", unique: true
    t.index ["work_status"], name: "index_adm_users_on_work_status"
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

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "sessions", "adm_users", column: "user_id"
end
