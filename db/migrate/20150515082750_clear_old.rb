class ClearOld < ActiveRecord::Migration
  def change
    drop_table :entries
    drop_table :flows
    drop_table :flow_steps
  end
end
