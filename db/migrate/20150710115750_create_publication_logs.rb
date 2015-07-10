class CreatePublicationLogs < ActiveRecord::Migration
  def change
    create_table :publication_logs do |t|
      t.string :type
      t.string :username
      t.text :comment

      t.timestamps null: false
    end
  end
end
