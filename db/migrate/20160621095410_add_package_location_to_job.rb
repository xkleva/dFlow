class AddPackageLocationToJob < ActiveRecord::Migration
  def change
    add_column :jobs, :package_location, :string
  end
end
