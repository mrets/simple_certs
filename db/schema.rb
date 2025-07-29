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

ActiveRecord::Schema[8.0].define(version: 2025_07_24_222743) do
  create_table "accounts", force: :cascade do |t|
    t.string "name"
    t.integer "organization_id"
    t.index ["organization_id"], name: "index_account_on_organization_id"
  end

  create_table "certificate_quantities", force: :cascade do |t|
    t.integer "sn_start"
    t.integer "quantity"
    t.integer "certificate_id"
    t.index ["certificate_id"], name: "index_certificate_quantities_on_certificate_id"
  end

  create_table "certificates", force: :cascade do |t|
    t.string "sn_base"
    t.integer "quantity"
    t.integer "generation_entry_id"
    t.index ["generation_entry_id"], name: "index_certificates_on_generation_entry_id"
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
  end

  create_table "organizations", force: :cascade do |t|
    t.string "name"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end
end
