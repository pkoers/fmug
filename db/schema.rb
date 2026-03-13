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

ActiveRecord::Schema[8.1].define(version: 2026_03_13_222500) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

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

  create_table "invitations", force: :cascade do |t|
    t.bigint "conference_id", null: false
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.datetime "expires_at", null: false
    t.string "first_name", null: false
    t.bigint "inviter_id", null: false
    t.string "token_digest", null: false
    t.datetime "updated_at", null: false
    t.datetime "used_at"
    t.index ["conference_id"], name: "index_invitations_on_conference_id"
    t.index ["email"], name: "index_invitations_on_email"
    t.index ["inviter_id"], name: "index_invitations_on_inviter_id"
    t.index ["token_digest"], name: "index_invitations_on_token_digest", unique: true
  end

  create_table "login_magic_links", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "token_digest", null: false
    t.datetime "updated_at", null: false
    t.datetime "used_at"
    t.bigint "user_id", null: false
    t.index ["token_digest"], name: "index_login_magic_links_on_token_digest", unique: true
    t.index ["user_id"], name: "index_login_magic_links_on_user_id"
  end

  create_table "magic_links", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "first_name", null: false
    t.bigint "invitation_id", null: false
    t.string "last_name", null: false
    t.string "token_digest", null: false
    t.datetime "updated_at", null: false
    t.datetime "used_at"
    t.index ["invitation_id"], name: "index_magic_links_on_invitation_id"
    t.index ["token_digest"], name: "index_magic_links_on_token_digest", unique: true
  end

  create_table "registrations", force: :cascade do |t|
    t.boolean "agenda_nothing_to_present", default: false, null: false
    t.boolean "agenda_present", default: false, null: false
    t.boolean "agenda_question", default: false, null: false
    t.boolean "agenda_something_else", default: false, null: false
    t.text "agenda_something_else_text"
    t.boolean "attending_physically", null: false
    t.text "chair_note"
    t.bigint "conference_id", null: false
    t.datetime "created_at", null: false
    t.text "dietary_requirements_text"
    t.boolean "has_dietary_requirements", default: false, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["conference_id"], name: "index_registrations_on_conference_id"
    t.index ["user_id", "conference_id"], name: "index_registrations_on_user_id_and_conference_id", unique: true
    t.index ["user_id"], name: "index_registrations_on_user_id"
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
    t.boolean "admin", default: false, null: false
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

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "identities", "users"
  add_foreign_key "invitations", "conferences"
  add_foreign_key "invitations", "users", column: "inviter_id"
  add_foreign_key "login_magic_links", "users"
  add_foreign_key "magic_links", "invitations"
  add_foreign_key "registrations", "conferences"
  add_foreign_key "registrations", "users"
  add_foreign_key "schedules", "conferences"
  add_foreign_key "users", "companies"
end
