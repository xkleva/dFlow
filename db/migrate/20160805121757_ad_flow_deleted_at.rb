class AdFlowDeletedAt < ActiveRecord::Migration
  def change
    add_column :flows, :deleted_at, :datetime, default: nil
  end
end
