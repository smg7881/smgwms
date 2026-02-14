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

ActiveRecord::Schema[8.1].define(version: 2026_02_14_090000) do
  create_table "adm_menus", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "menu_cd", limit: 20, null: false
    t.string "menu_icon", limit: 10
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

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address"
    t.string "password_digest"
    t.datetime "updated_at", null: false
  end

  add_foreign_key "sessions", "users"
end
