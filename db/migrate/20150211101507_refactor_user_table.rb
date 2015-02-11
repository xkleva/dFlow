class RefactorUserTable < ActiveRecord::Migration
  def change
  	remove_column :users, :role_id
  	add_column :users, :role, :text
  	remove_column :users, :password
  end
end
