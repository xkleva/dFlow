class AddColumnStateToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :state, :text
  end
end
