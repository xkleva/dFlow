class ReplaceSourceIdColumnInJobs < ActiveRecord::Migration
  def change
    remove_column :jobs, :source_id
    add_column :jobs, :source, :text
  end
end
