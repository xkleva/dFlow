class AddJobIdAndEventIndexesOnJobActivities < ActiveRecord::Migration
  def change
  	add_index :job_activities, :job_id, using: 'btree'
  	add_index :job_activities, :event, using: 'btree'
  end
end
