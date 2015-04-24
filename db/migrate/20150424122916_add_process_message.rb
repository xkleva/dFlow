class AddProcessMessage < ActiveRecord::Migration
  def change
    add_column :jobs, :process_message, :text
  end
end
