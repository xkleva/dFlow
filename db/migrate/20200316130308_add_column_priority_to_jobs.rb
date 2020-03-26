class AddColumnPriorityToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :priority, :integer, default: 2, null: false
  end
end
