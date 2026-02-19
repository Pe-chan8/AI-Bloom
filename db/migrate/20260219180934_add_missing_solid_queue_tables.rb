# frozen_string_literal: true

class AddMissingSolidQueueTables < ActiveRecord::Migration[8.1]
  def change
    create_table :solid_queue_ready_executions, if_not_exists: true do |t|
      t.references :job, null: false, foreign_key: { to_table: :solid_queue_jobs }
      t.datetime :created_at, null: false
    end
    add_index :solid_queue_ready_executions, :job_id, unique: true, if_not_exists: true

    create_table :solid_queue_recurring_tasks, if_not_exists: true do |t|
      t.string  :key, null: false
      t.string  :schedule, null: false
      t.string  :command, null: false
      t.string  :queue_name, null: false, default: "default"
      t.integer :priority, null: false, default: 0
      t.datetime :last_run_at
      t.datetime :next_run_at
      t.boolean :enabled, null: false, default: true
      t.timestamps
    end
    add_index :solid_queue_recurring_tasks, :key, unique: true, if_not_exists: true
    add_index :solid_queue_recurring_tasks, :next_run_at, if_not_exists: true
  end
end
