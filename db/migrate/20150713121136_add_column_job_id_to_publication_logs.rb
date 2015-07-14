class AddColumnJobIdToPublicationLogs < ActiveRecord::Migration
  def change
    add_column :publication_logs, :job_id, :integer
  end
end
