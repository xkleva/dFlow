class CreateJobActivities < ActiveRecord::Migration
  def change
    create_table :job_activities do |t|
      t.integer :job_id
      t.text :username
      t.text :event
      t.text :message

      t.timestamps null: false
    end
  end
end
