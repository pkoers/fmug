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

ActiveRecord::Schema[8.1].define(version: 2026_03_08_191500) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "companies", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "iata_code"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["iata_code"], name: "index_companies_on_iata_code", unique: true
    t.index ["name"], name: "index_companies_on_name"
  end

  create_table "conferences", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "current"
    t.integer "edition"
    t.date "end_date"
    t.string "host"
    t.text "location"
    t.date "start_date"
    t.datetime "updated_at", null: false
  end

  create_table "identities", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "provider", null: false
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["provider", "uid"], name: "index_identities_on_provider_and_uid", unique: true
    t.index ["user_id", "provider"], name: "index_identities_on_user_id_and_provider", unique: true
    t.index ["user_id"], name: "index_identities_on_user_id"
  end

  create_table "schedules", force: :cascade do |t|
    t.bigint "conference_id", null: false
    t.datetime "created_at", null: false
    t.integer "day"
    t.text "description"
    t.integer "length"
    t.time "time"
    t.datetime "updated_at", null: false
    t.index ["conference_id"], name: "index_schedules_on_conference_id"
  end

  create_table "users", force: :cascade do |t|
    t.bigint "company_id"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "role", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_users_on_company_id"
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "identities", "users"
  add_foreign_key "schedules", "conferences"
  add_foreign_key "users", "companies"
end
