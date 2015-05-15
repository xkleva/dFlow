class AddDescriptionToTableFlowSteps < ActiveRecord::Migration
  def change
    add_column :flow_steps, :description, :text
  end
end
