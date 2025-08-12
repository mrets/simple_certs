# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_08_10_152939) do
  create_table "accounts", force: :cascade do |t|
    t.string "name"
    t.integer "organization_id"
    t.index ["organization_id"], name: "index_account_on_organization_id"
  end

  create_table "certificate_quantities", force: :cascade do |t|
    t.integer "quantity"
    t.integer "certificate_id"
    t.integer "account_id"
    t.string "status"
    t.integer "to_organization_id"
    t.index ["account_id"], name: "index_certificate_quantities_on_account_id"
    t.index ["certificate_id"], name: "index_certificate_quantities_on_certificate_id"
    t.index ["to_organization_id"], name: "index_certificate_quantities_on_to_organization_id"
  end

  create_table "certificates", force: :cascade do |t|
    t.string "sn_base"
    t.integer "quantity"
    t.integer "generation_id"
    t.integer "generator_id"
    t.date "vintage_date"
    t.index ["generation_id"], name: "index_certificates_on_generation_id"
    t.index ["generator_id"], name: "index_certificates_on_generator_id"
  end

  create_table "event_store_events", force: :cascade do |t|
    t.string "event_id", limit: 36, null: false
    t.string "event_type", null: false
    t.binary "metadata"
    t.binary "data", null: false
    t.datetime "created_at", null: false
    t.datetime "valid_at"
    t.index ["created_at"], name: "index_event_store_events_on_created_at"
    t.index ["event_id"], name: "index_event_store_events_on_event_id", unique: true
    t.index ["event_type"], name: "index_event_store_events_on_event_type"
    t.index ["valid_at"], name: "index_event_store_events_on_valid_at"
  end

  create_table "event_store_events_in_streams", force: :cascade do |t|
    t.string "stream", null: false
    t.integer "position"
    t.string "event_id", limit: 36, null: false
    t.datetime "created_at", null: false
    t.index ["created_at"], name: "index_event_store_events_in_streams_on_created_at"
    t.index ["event_id"], name: "index_event_store_events_in_streams_on_event_id"
    t.index ["stream", "event_id"], name: "index_event_store_events_in_streams_on_stream_and_event_id", unique: true
    t.index ["stream", "position"], name: "index_event_store_events_in_streams_on_stream_and_position", unique: true
  end

  create_table "generations", force: :cascade do |t|
    t.date "start_date"
    t.date "end_date"
    t.integer "quantity"
    t.integer "generator_id"
    t.index ["generator_id"], name: "index_generations_on_generator_id"
  end

  create_table "generators", force: :cascade do |t|
    t.string "name"
    t.string "ext_id"
    t.integer "organization_id"
    t.index ["organization_id"], name: "index_generators_on_organization_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.string "name"
    t.integer "default_account_id"
    t.index ["default_account_id"], name: "index_organizations_on_default_account_id"
  end

  create_table "transactions", force: :cascade do |t|
    t.string "request_uuid", limit: 36, null: false
    t.integer "request_user_id", null: false
    t.datetime "initiated_at", null: false
    t.datetime "recorded_at", null: false
    t.string "resource", null: false
    t.string "action", null: false
    t.boolean "completed", null: false
    t.integer "record_id"
    t.string "old_state"
    t.string "new_state"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "api_key"
    t.integer "organization_id"
    t.index ["organization_id"], name: "index_users_on_organization_id"
  end

  add_foreign_key "event_store_events_in_streams", "event_store_events", column: "event_id", primary_key: "event_id"
end
