# frozen_string_literal: true

class CreateSolidQueueTables < ActiveRecord::Migration[8.1]
  def change
    create_table :solid_queue_processes do |t|
      t.string  :name, null: false
      t.integer :pid, null: false
      t.datetime :last_heartbeat_at
      t.timestamps
    end

    create_table :solid_queue_workers do |t|
      t.references :process, null: false, foreign_key: { to_table: :solid_queue_processes }
      t.string :name, null: false
      t.timestamps
    end

    create_table :solid_queue_queues do |t|
      t.string :name, null: false
      t.timestamps
    end
    add_index :solid_queue_queues, :name, unique: true

    create_table :solid_queue_jobs do |t|
      t.string  :queue_name, null: false
      t.string  :class_name, null: false
      t.text    :arguments
      t.integer :priority, default: 0, null: false
      t.datetime :scheduled_at
      t.datetime :finished_at
      t.string  :concurrency_key
      t.string  :active_job_id
      t.string  :status, null: false, default: "queued"
      t.text    :error
      t.timestamps
    end

    add_index :solid_queue_jobs, [ :queue_name, :scheduled_at ]
    add_index :solid_queue_jobs, :active_job_id
    add_index :solid_queue_jobs, :concurrency_key
    add_index :solid_queue_jobs, :status
  end
end
