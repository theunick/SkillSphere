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

ActiveRecord::Schema.define(version: 2024_07_05_101456) do

  create_table "accounts", force: :cascade do |t|
    t.string "uid"
    t.string "provider"
    t.string "email"
    t.string "name"
    t.string "surname"
    t.string "image"
    t.string "oauth_token"
    t.datetime "oauth_expires_at"
    t.integer "role"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "assistance_requests", force: :cascade do |t|
    t.text "description"
    t.string "status"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "account_id"
    t.text "message"
    t.text "response"
    t.boolean "hidden", default: false
  end

  create_table "assistances", force: :cascade do |t|
    t.text "message"
    t.integer "account_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["account_id"], name: "index_assistances_on_account_id"
  end

  create_table "cart_items", force: :cascade do |t|
    t.integer "cart_id", null: false
    t.integer "course_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["cart_id"], name: "index_cart_items_on_cart_id"
    t.index ["course_id"], name: "index_cart_items_on_course_id"
  end

  create_table "carts", force: :cascade do |t|
    t.integer "account_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["account_id"], name: "index_carts_on_account_id"
  end

  create_table "courses", force: :cascade do |t|
    t.string "title"
    t.string "code"
    t.string "category"
    t.integer "seller_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "description"
    t.json "google_drive_file_ids"
    t.decimal "price"
    t.boolean "hidden", default: false
    t.index ["seller_id"], name: "index_courses_on_seller_id"
  end

  create_table "impressions", force: :cascade do |t|
    t.string "impressionable_type"
    t.integer "impressionable_id"
    t.integer "user_id"
    t.string "controller_name"
    t.string "action_name"
    t.string "view_name"
    t.string "request_hash"
    t.string "ip_address"
    t.string "session_hash"
    t.text "message"
    t.text "referrer"
    t.text "params"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["controller_name", "action_name", "ip_address"], name: "controlleraction_ip_index"
    t.index ["controller_name", "action_name", "request_hash"], name: "controlleraction_request_index"
    t.index ["controller_name", "action_name", "session_hash"], name: "controlleraction_session_index"
    t.index ["impressionable_type", "impressionable_id", "ip_address"], name: "poly_ip_index"
    t.index ["impressionable_type", "impressionable_id", "params"], name: "poly_params_request_index"
    t.index ["impressionable_type", "impressionable_id", "request_hash"], name: "poly_request_index"
    t.index ["impressionable_type", "impressionable_id", "session_hash"], name: "poly_session_index"
    t.index ["impressionable_type", "message", "impressionable_id"], name: "impressionable_type_message_index"
    t.index ["user_id"], name: "index_impressions_on_user_id"
  end

  create_table "purchases", force: :cascade do |t|
    t.integer "account_id", null: false
    t.integer "course_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["account_id"], name: "index_purchases_on_account_id"
    t.index ["course_id"], name: "index_purchases_on_course_id"
  end

  create_table "reports", force: :cascade do |t|
    t.integer "account_id", null: false
    t.integer "course_id", null: false
    t.string "message"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "subject"
    t.text "description"
    t.index ["account_id"], name: "index_reports_on_account_id"
    t.index ["course_id"], name: "index_reports_on_course_id"
  end

  create_table "reviews", force: :cascade do |t|
    t.integer "course_id", null: false
    t.text "content"
    t.integer "rating"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "account_id"
    t.index ["course_id"], name: "index_reviews_on_course_id"
  end

  add_foreign_key "assistances", "accounts"
  add_foreign_key "cart_items", "carts"
  add_foreign_key "cart_items", "courses"
  add_foreign_key "carts", "accounts"
  add_foreign_key "courses", "accounts", column: "seller_id"
  add_foreign_key "purchases", "accounts"
  add_foreign_key "purchases", "courses"
  add_foreign_key "reports", "accounts"
  add_foreign_key "reports", "courses"
  add_foreign_key "reviews", "courses"
end
