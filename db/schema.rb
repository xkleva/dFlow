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

ActiveRecord::Schema.define(version: 20200316130308) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "access_tokens", force: :cascade do |t|
    t.integer  "user_id"
    t.text     "token"
    t.datetime "token_expire"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  create_table "flow_steps", force: :cascade do |t|
    t.integer  "step"
    t.integer  "job_id"
    t.text     "process"
    t.integer  "goto_true"
    t.integer  "goto_false"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.datetime "aborted_at"
    t.text     "params"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.text     "description"
    t.text     "process_msg"
    t.datetime "entered_at"
    t.string   "status"
    t.string   "condition"
    t.integer  "flow_id"
    t.text     "comment"
  end

  add_index "flow_steps", ["job_id"], name: "idx_flow_steps_job_id", using: :btree
  add_index "flow_steps", ["step"], name: "idx_flow_steps_step", using: :btree

  create_table "flows", force: :cascade do |t|
    t.string   "name"
    t.text     "description"
    t.text     "parameters",   default: "[]"
    t.text     "folder_paths", default: "[]"
    t.text     "steps",        default: "[]"
    t.boolean  "active",       default: true
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "job_activities", force: :cascade do |t|
    t.integer  "job_id"
    t.text     "username"
    t.text     "event"
    t.text     "message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "jobs", force: :cascade do |t|
    t.text     "name"
    t.text     "catalog_id"
    t.text     "title"
    t.text     "author"
    t.datetime "deleted_at"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.text     "xml"
    t.boolean  "quarantined",       default: false
    t.text     "comment"
    t.text     "object_info"
    t.text     "search_title"
    t.text     "metadata",          default: ""
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "source"
    t.integer  "treenode_id"
    t.string   "status"
    t.boolean  "copyright",                         null: false
    t.text     "process_message"
    t.text     "package_metadata",  default: ""
    t.integer  "parent_ids",        default: [],                 array: true
    t.integer  "current_flow_step"
    t.text     "flow_name"
    t.text     "state"
    t.string   "package_location"
    t.text     "flow_parameters",   default: ""
    t.integer  "flow_id"
    t.text     "scanner_make"
    t.text     "scanner_model"
    t.text     "scanner_software"
    t.integer  "priority",          default: 2,     null: false
  end

  add_index "jobs", ["parent_ids"], name: "index_jobs_on_parent_ids", using: :gin

  create_table "publication_logs", force: :cascade do |t|
    t.string   "publication_type"
    t.string   "username"
    t.text     "comment"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.integer  "job_id"
  end

  create_table "queue_manager_pids", force: :cascade do |t|
    t.integer  "pid"
    t.datetime "started_at"
    t.datetime "aborted_at"
    t.datetime "finished_at"
    t.text     "version_string"
    t.integer  "last_flow_step_id"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
  end

  create_table "treenodes", force: :cascade do |t|
    t.string   "name"
    t.integer  "parent_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
  end

  create_table "users", force: :cascade do |t|
    t.text     "email"
    t.text     "username"
    t.text     "name"
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "role"
    t.text     "password"
  end

end
