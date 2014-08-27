# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20140814142309) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "entries", force: true do |t|
    t.integer  "job_id"
    t.integer  "flow_step_id"
    t.string   "state"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "flow_steps", force: true do |t|
    t.integer  "flow_id"
    t.integer  "process_id"
    t.string   "goto_true"
    t.string   "goto_false"
    t.string   "condition_method"
    t.string   "condition_operator"
    t.string   "condition_value"
    t.string   "params"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "flows", force: true do |t|
    t.string   "name"
    t.integer  "start_position"
    t.text     "params_info"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "jobs", force: true do |t|
    t.text     "name"
    t.integer  "source_id"
    t.integer  "catalog_id"
    t.text     "title"
    t.text     "author"
    t.datetime "deleted_at"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.text     "xml"
    t.boolean  "quarantined",    default: false
    t.text     "comment"
    t.text     "object_info"
    t.text     "search_title"
    t.text     "metadata",       default: ""
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "progress_state"
    t.integer  "flow_id"
    t.text     "flow_params"
  end

  create_table "roles", force: true do |t|
    t.text     "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sources", force: true do |t|
    t.text     "classname"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: true do |t|
    t.integer  "role_id"
    t.text     "email"
    t.text     "username"
    t.text     "password"
    t.text     "name"
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
