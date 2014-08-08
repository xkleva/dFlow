class CreateJobs < ActiveRecord::Migration
	def change
		create_table :jobs do |t|
			t.text     "name"
			t.integer  "source_id"
			t.integer  "catalog_id"
			t.text     "title"
			t.text     "author"
			t.datetime "deleted_at"
			t.integer  "created_by"
			t.integer  "updated_by"
			t.text     "xml"
			t.boolean  "quarantined", default: false
			t.text     "comment"
			t.text     "object_info"
			t.text     "search_title"
			t.text     "metadata", default: ""
			t.timestamps
		end
	end
end
