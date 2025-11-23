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

ActiveRecord::Schema[8.1].define(version: 2025_11_23_051954) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "diagnosis_questions", force: :cascade do |t|
    t.string "category"
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.integer "position", null: false
    t.datetime "updated_at", null: false
    t.index ["position"], name: "index_diagnosis_questions_on_position", unique: true
  end

  create_table "posts", force: :cascade do |t|
    t.text "ai_summary"
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.text "image_url"
    t.integer "mood"
    t.datetime "posted_at"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.integer "visibility", default: 0, null: false
    t.index ["user_id"], name: "index_posts_on_user_id"
    t.index ["visibility", "posted_at"], name: "index_posts_on_visibility_and_posted_at"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "recommended_buddy_type"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "social_type"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "posts", "users"
end
