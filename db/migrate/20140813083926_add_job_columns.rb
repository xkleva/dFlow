class AddJobColumns < ActiveRecord::Migration
  def change
  	add_column :jobs, :progress_state, :text
  	add_column :jobs, :workflow_id, :integer
  	add_column :jobs, :workflow_param_values, :text
  end
end
