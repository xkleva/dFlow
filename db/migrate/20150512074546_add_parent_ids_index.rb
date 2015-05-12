class AddParentIdsIndex < ActiveRecord::Migration
  def change
    add_index  :jobs, :parent_ids, using: 'gin'
  end
end
