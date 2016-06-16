class AddStatusFIeldToFlowStep < ActiveRecord::Migration
  def change
    add_column :flow_steps, :status, :string
  end
end
