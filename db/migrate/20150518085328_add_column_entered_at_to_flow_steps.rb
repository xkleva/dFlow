class AddColumnEnteredAtToFlowSteps < ActiveRecord::Migration
  def change
    add_column :flow_steps, :entered_at, :timestamp
  end
end
