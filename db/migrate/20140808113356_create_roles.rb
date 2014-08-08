class CreateRoles < ActiveRecord::Migration
	def change
		create_table :roles do |t|
			t.text     "name"
			t.timestamps
		end
		Role.reset_column_information
		Role.create(name: "guest")
		Role.create(name: "operator")
		Role.create(name: "admin")
	end
end
