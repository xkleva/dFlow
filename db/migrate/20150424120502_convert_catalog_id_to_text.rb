class ConvertCatalogIdToText < ActiveRecord::Migration
  def change
    change_column :jobs, :catalog_id, :text
  end
end
