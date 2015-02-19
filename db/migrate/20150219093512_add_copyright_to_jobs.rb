class AddCopyrightToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :copyright, :boolean, required: 'false'
  end
end
