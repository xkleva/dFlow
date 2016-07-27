class AddFlowStepCondition < ActiveRecord::Migration
  def change
    add_column :flow_steps, :condition, :string
  end
end
