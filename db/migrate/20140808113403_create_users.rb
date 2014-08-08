class CreateUsers < ActiveRecord::Migration
	def change
		create_table :users do |t|
			t.integer  "role_id"
			t.text     "email"
			t.text     "username"
			t.text     "password"
			t.text     "name"
			t.datetime "deleted_at"
			t.timestamps
		end
	end
end
