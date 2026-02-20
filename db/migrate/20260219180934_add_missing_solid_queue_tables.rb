# frozen_string_literal: true

class AddMissingSolidQueueTables < ActiveRecord::Migration[8.1]
  def change
    # -----------------------
    # ready_executions
    # -----------------------
    create_table :solid_queue_ready_executions, if_not_exists: true do |t|
      t.bigint :job_id, null: false
      t.string :queue_name, null: false
      t.integer :priority, null: false, default: 0
      t.datetime :created_at, null: false
    end

    add_index :solid_queue_ready_executions, :job_id, unique: true, if_not_exists: true

    # -----------------------
    # recurring_tasks
    # -----------------------
    create_table :solid_queue_recurring_tasks, if_not_exists: true do |t|
      t.string :key, null: false
      t.string :schedule, null: false
      t.string :command, null: false

      t.string :class_name
      t.text :arguments
      t.string :queue_name
      t.integer :priority
      t.boolean :static, null: false, default: false
      t.string :description
      t.boolean :enabled, null: false, default: true
      t.datetime :last_run_at
      t.datetime :next_run_at

      t.timestamps
    end

    add_index :solid_queue_recurring_tasks, :key, unique: true, if_not_exists: true
    add_index :solid_queue_recurring_tasks, :next_run_at, if_not_exists: true

    create_table :solid_queue_claimed_executions, if_not_exists: true do |t|
      t.bigint :job_id, null: false
      t.bigint :process_id, null: false
      t.datetime :created_at, null: false
    end
    add_index :solid_queue_claimed_executions, :job_id, unique: true, if_not_exists: true
    add_index :solid_queue_claimed_executions, :process_id, if_not_exists: true

    create_table :solid_queue_pauses, if_not_exists: true do |t|
      t.string :queue_name, null: false
      t.datetime :created_at, null: false
    end
    add_index :solid_queue_pauses, :queue_name, unique: true, if_not_exists: true

    create_table :solid_queue_scheduled_executions, if_not_exists: true do |t|
      t.bigint :job_id, null: false
      t.datetime :scheduled_at, null: false
      t.datetime :created_at, null: false
    end
    add_index :solid_queue_scheduled_executions, :job_id, unique: true, if_not_exists: true
    add_index :solid_queue_scheduled_executions, :scheduled_at, if_not_exists: true
  end
end
