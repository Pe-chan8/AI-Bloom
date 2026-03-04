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

ActiveRecord::Schema[8.1].define(version: 2026_02_23_094904) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "ai_logs", force: :cascade do |t|
    t.bigint "ai_message_id"
    t.integer "completion_tokens"
    t.datetime "created_at", null: false
    t.string "error_class"
    t.text "error_message"
    t.integer "latency_ms"
    t.string "model", null: false
    t.bigint "post_id"
    t.integer "prompt_tokens"
    t.string "provider", default: "openai", null: false
    t.datetime "requested_at"
    t.datetime "responded_at"
    t.string "status", default: "success", null: false
    t.integer "total_tokens"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.string "variant"
    t.index ["ai_message_id"], name: "index_ai_logs_on_ai_message_id"
    t.index ["post_id", "created_at"], name: "index_ai_logs_on_post_id_and_created_at"
    t.index ["post_id"], name: "index_ai_logs_on_post_id"
    t.index ["status"], name: "index_ai_logs_on_status"
    t.index ["user_id", "created_at"], name: "index_ai_logs_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_ai_logs_on_user_id"
  end

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
    t.string "category", default: "all", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.integer "kind", default: 2, null: false
    t.bigint "post_id"
    t.integer "sentiment"
    t.string "subcategory"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["buddy_id"], name: "index_ai_messages_on_buddy_id"
    t.index ["post_id"], name: "index_ai_messages_on_post_id"
    t.index ["user_id", "kind", "category", "subcategory", "created_at"], name: "idx_ai_messages_analysis_scope"
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

  create_table "buddy_messages", force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.bigint "post_id", null: false
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["post_id", "created_at"], name: "index_buddy_messages_on_post_id_and_created_at"
    t.index ["post_id"], name: "index_buddy_messages_on_post_id"
    t.index ["user_id"], name: "index_buddy_messages_on_user_id"
  end

  create_table "diagnosis_questions", force: :cascade do |t|
    t.string "category"
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.integer "position", null: false
    t.datetime "updated_at", null: false
    t.index ["position"], name: "index_diagnosis_questions_on_position", unique: true
  end

  create_table "favorites", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "post_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["post_id"], name: "index_favorites_on_post_id"
    t.index ["user_id", "post_id"], name: "index_favorites_on_user_id_and_post_id", unique: true
    t.index ["user_id"], name: "index_favorites_on_user_id"
  end

  create_table "posts", force: :cascade do |t|
    t.text "ai_summary"
    t.text "body", null: false
    t.bigint "buddy_id"
    t.string "category"
    t.datetime "created_at", null: false
    t.text "image_url"
    t.integer "mood"
    t.datetime "posted_at"
    t.string "subcategory"
    t.string "tags_text"
    t.string "title"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.integer "visibility", default: 0, null: false
    t.index ["buddy_id"], name: "index_posts_on_buddy_id"
    t.index ["user_id"], name: "index_posts_on_user_id"
    t.index ["visibility", "posted_at"], name: "index_posts_on_visibility_and_posted_at"
  end

  create_table "social_type_results", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "diagnosed_at", null: false
    t.integer "dominant_type", null: false
    t.string "question_set_key"
    t.integer "schema_version", default: 4, null: false
    t.jsonb "scores", default: {}, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["diagnosed_at"], name: "index_social_type_results_on_diagnosed_at"
    t.index ["user_id"], name: "index_social_type_results_on_user_id"
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.bigint "process_id", null: false
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id"], name: "index_solid_queue_claimed_executions_on_process_id"
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "active_job_id"
    t.text "arguments"
    t.string "class_name", null: false
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.text "error"
    t.datetime "finished_at"
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at"
    t.string "status", default: "queued", null: false
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["concurrency_key"], name: "index_solid_queue_jobs_on_concurrency_key"
    t.index ["queue_name", "scheduled_at"], name: "index_solid_queue_jobs_on_queue_name_and_scheduled_at"
    t.index ["status"], name: "index_solid_queue_jobs_on_status"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "queue_name", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "last_heartbeat_at"
    t.string "name", null: false
    t.integer "pid", null: false
    t.datetime "updated_at", null: false
  end

  create_table "solid_queue_queues", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_solid_queue_queues_on_name", unique: true
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.text "arguments"
    t.string "class_name"
    t.string "command", null: false
    t.datetime "created_at", null: false
    t.string "description"
    t.boolean "enabled", default: true, null: false
    t.string "key", null: false
    t.datetime "last_run_at"
    t.datetime "next_run_at"
    t.integer "priority"
    t.string "queue_name"
    t.string "schedule", null: false
    t.boolean "static", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["next_run_at"], name: "index_solid_queue_recurring_tasks_on_next_run_at"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.datetime "scheduled_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at"], name: "index_solid_queue_scheduled_executions_on_scheduled_at"
  end

  create_table "solid_queue_workers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "process_id", null: false
    t.datetime "updated_at", null: false
    t.index ["process_id"], name: "index_solid_queue_workers_on_process_id"
  end

  create_table "users", force: :cascade do |t|
    t.bigint "buddy_id"
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.bigint "current_buddy_id"
    t.string "dominant_type"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "nickname"
    t.datetime "onboarded_at"
    t.string "provider"
    t.string "recommended_buddy_type"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "social_type"
    t.string "uid"
    t.string "unconfirmed_email"
    t.datetime "updated_at", null: false
    t.index ["buddy_id"], name: "index_users_on_buddy_id"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["current_buddy_id"], name: "index_users_on_current_buddy_id"
    t.index ["dominant_type"], name: "index_users_on_dominant_type"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["onboarded_at"], name: "index_users_on_onboarded_at"
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "ai_logs", "ai_messages", on_delete: :cascade
  add_foreign_key "ai_logs", "posts", on_delete: :cascade
  add_foreign_key "ai_logs", "users"
  add_foreign_key "ai_message_feedbacks", "ai_messages"
  add_foreign_key "ai_message_feedbacks", "users"
  add_foreign_key "ai_messages", "buddies"
  add_foreign_key "ai_messages", "posts"
  add_foreign_key "ai_messages", "users"
  add_foreign_key "buddy_messages", "posts", on_delete: :cascade
  add_foreign_key "buddy_messages", "users"
  add_foreign_key "favorites", "posts"
  add_foreign_key "favorites", "users"
  add_foreign_key "posts", "buddies"
  add_foreign_key "posts", "users"
  add_foreign_key "social_type_results", "users"
  add_foreign_key "solid_queue_workers", "solid_queue_processes", column: "process_id"
  add_foreign_key "users", "buddies"
end
