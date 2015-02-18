class AddStatusToJob < ActiveRecord::Migration
  def change
    add_column :jobs, :status, :string
    remove_column :jobs, :flow_id
    remove_column :jobs, :flow_params
    remove_column :jobs, :progress_state
  end
end
