class CreateFlowSteps < ActiveRecord::Migration
  def change
    create_table :flow_steps do |t|
      t.integer :step
      t.integer :job_id
      t.text :process
      t.integer :goto_true
      t.integer :goto_false
      t.timestamp :started_at
      t.timestamp :finished_at
      t.timestamp :aborted_at
      t.text :params
      t.timestamps null: false
    end
  end
end
