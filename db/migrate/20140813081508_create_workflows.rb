class CreateWorkflows < ActiveRecord::Migration
	def change
		create_table :workflows do |t|
			t.string :name
			t.integer :start_position
			t.text :workflow_param_info
			t.timestamps
		end
	end
end
