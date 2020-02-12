class AddScannerInfoColumnsToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :scanner_make, :text
    add_column :jobs, :scanner_model, :text
    add_column :jobs, :scanner_software, :text
  end
end
