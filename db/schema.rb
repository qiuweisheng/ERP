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

ActiveRecord::Schema.define(version: 20141106115537) do

  create_table "clients", force: true do |t|
    t.integer  "account_id"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "employees", force: true do |t|
    t.integer  "account_id"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "products", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "records", force: true do |t|
    t.integer  "record_type"
    t.integer  "origin_id"
    t.integer  "product_id"
    t.decimal  "weight"
    t.integer  "count",       default: 0
    t.integer  "user_id"
    t.integer  "client_id"
    t.string   "client_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "records", ["client_id", "client_type"], name: "index_records_on_client_id_and_client_type"
  add_index "records", ["origin_id"], name: "index_records_on_origin_id"
  add_index "records", ["product_id"], name: "index_records_on_product_id"
  add_index "records", ["user_id"], name: "index_records_on_user_id"

  create_table "users", force: true do |t|
    t.integer  "account_id"
    t.string   "name"
    t.string   "password_digest"
    t.integer  "permission"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
