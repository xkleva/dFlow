class AddTreenodeIdToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :treenode_id, :integer
  end
end
