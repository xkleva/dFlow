class AddColumnSelectableToFlows < ActiveRecord::Migration
  def change
    add_column :flows, :selectable, :boolean, default: true
  end
end
