class AddProcessColumns < ActiveRecord::Migration
  def change
    add_column :flow_steps, :process_msg, :text
    add_column :jobs, :current_flow_step, :integer
  end
end
