class CreateProcessingEntries < ActiveRecord::Migration
	def change
		create_table :processing_entries do |t|
			t.integer :job_id
			t.integer :workflow_step_id
			t.string :state
			t.timestamps
		end
	end
end
