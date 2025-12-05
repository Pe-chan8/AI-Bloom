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

ActiveRecord::Schema[8.1].define(version: 2025_12_05_064615) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "ai_message_feedbacks", force: :cascade do |t|
    t.bigint "ai_message_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.integer "value", null: false
    t.index ["ai_message_id"], name: "index_ai_message_feedbacks_on_ai_message_id"
    t.index ["user_id", "ai_message_id"], name: "index_ai_message_feedbacks_on_user_id_and_ai_message_id", unique: true
    t.index ["user_id"], name: "index_ai_message_feedbacks_on_user_id"
  end

  create_table "ai_messages", force: :cascade do |t|
    t.bigint "buddy_id"
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.integer "kind", default: 2, null: false
    t.bigint "post_id"
    t.integer "sentiment"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["buddy_id"], name: "index_ai_messages_on_buddy_id"
    t.index ["post_id"], name: "index_ai_messages_on_post_id"
    t.index ["user_id"], name: "index_ai_messages_on_user_id"
  end

  create_table "buddies", force: :cascade do |t|
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.boolean "is_active", default: true, null: false
    t.string "name", null: false
    t.text "persona_prompt"
    t.text "tone_hint"
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_buddies_on_code", unique: true
  end

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
    t.bigint "buddy_id"
    t.datetime "created_at", null: false
    t.bigint "current_buddy_id"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "recommended_buddy_type"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "social_type"
    t.datetime "updated_at", null: false
    t.index ["buddy_id"], name: "index_users_on_buddy_id"
    t.index ["current_buddy_id"], name: "index_users_on_current_buddy_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "ai_message_feedbacks", "ai_messages"
  add_foreign_key "ai_message_feedbacks", "users"
  add_foreign_key "ai_messages", "buddies"
  add_foreign_key "ai_messages", "posts"
  add_foreign_key "ai_messages", "users"
  add_foreign_key "posts", "users"
  add_foreign_key "users", "buddies"
end
