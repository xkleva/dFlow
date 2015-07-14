class RenameColumnType < ActiveRecord::Migration
  def change
    rename_column :publication_logs, :type, :publication_type
  end
end
