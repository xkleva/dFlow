class RequireCopyrightInJobs < ActiveRecord::Migration
  def change
    Job.find_each do |job|
      job.copyright = 'false'
      job.save!
    end
    change_column :jobs, :copyright, :boolean, required: 'true'
    change_column_null :jobs, :copyright, false
  end
end
