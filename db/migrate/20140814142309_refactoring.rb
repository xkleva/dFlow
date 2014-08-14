class Refactoring < ActiveRecord::Migration
  def change
  	rename_column :jobs, :workflow_id, :flow_id
  	rename_column :jobs, :workflow_param_values, :flow_params
  	rename_column :processing_entries, :workflow_step_id, :flow_step_id
  	rename_column :workflows, :workflow_param_info, :params_info
  	rename_column :workflow_steps, :workflow_id, :flow_id
  	change_column :workflow_steps, :process_id, :integer
  	rename_table :processing_entries, :entries
  	rename_table :workflows, :flows
  	rename_table :workflow_steps, :flow_steps
  end
end
