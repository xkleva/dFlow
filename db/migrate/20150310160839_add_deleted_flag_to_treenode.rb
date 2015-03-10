class AddDeletedFlagToTreenode < ActiveRecord::Migration
  def change
    add_column :treenodes, :deleted_at, :datetime
  end
end
