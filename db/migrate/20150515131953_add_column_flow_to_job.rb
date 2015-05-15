class AddColumnFlowToJob < ActiveRecord::Migration
  def change
    add_column :jobs, :flow, :text
  end
end
