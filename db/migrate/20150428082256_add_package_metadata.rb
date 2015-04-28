class AddPackageMetadata < ActiveRecord::Migration
  def change
    add_column :jobs, :package_metadata, :text, default: ""
  end
end
