class AddParentIdsColumn < ActiveRecord::Migration
  def change
    add_column :jobs, :parent_ids, :integer, array: true, default: '{}'
  end
end
