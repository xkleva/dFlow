class CreateWorkflowSteps < ActiveRecord::Migration
	def change
		create_table :workflow_steps do |t|
			t.integer :workflow_id
			t.integer :process_id
			t.string :goto_true
			t.string :goto_false
			t.string :condition_method
			t.string :condition_operator
			t.string :condition_value
			t.string :params
			t.timestamps
		end
	end
end
