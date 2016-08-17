class CreateQueueManagerPids < ActiveRecord::Migration
  def change
    create_table :queue_manager_pids do |t|
      t.integer :pid
      t.datetime :started_at
      t.datetime :aborted_at
      t.datetime :finished_at
      t.text :version_string
      t.integer :last_flow_step_id

      t.timestamps null: false
    end
  end
end
