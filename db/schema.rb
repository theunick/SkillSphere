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

ActiveRecord::Schema.define(version: 2024_07_03_083825) do

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
    t.integer "user_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["user_id"], name: "index_assistances_on_user_id"
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
    t.index ["seller_id"], name: "index_courses_on_seller_id"
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
    t.integer "user_id", null: false
    t.integer "course_id", null: false
    t.text "content"
    t.integer "rating"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["course_id"], name: "index_reviews_on_course_id"
    t.index ["user_id"], name: "index_reviews_on_user_id"
  end

  add_foreign_key "assistances", "users"
  add_foreign_key "courses", "accounts", column: "seller_id"
  add_foreign_key "reports", "accounts"
  add_foreign_key "reports", "courses"
  add_foreign_key "reviews", "courses"
  add_foreign_key "reviews", "users"
end
