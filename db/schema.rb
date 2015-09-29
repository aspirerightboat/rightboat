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

ActiveRecord::Schema.define(version: 20150929160334) do

  create_table "addresses", force: :cascade do |t|
    t.string   "line1",            limit: 255
    t.string   "line2",            limit: 255
    t.string   "town_city",        limit: 255
    t.string   "county",           limit: 255
    t.integer  "country_id",       limit: 4
    t.string   "zip",              limit: 255
    t.integer  "addressible_id",   limit: 4
    t.string   "addressible_type", limit: 255
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
  end

  add_index "addresses", ["addressible_type", "addressible_id"], name: "index_addresses_on_addressible_type_and_addressible_id", using: :btree
  add_index "addresses", ["country_id"], name: "index_addresses_on_country_id", using: :btree

  create_table "article_authors", force: :cascade do |t|
    t.string   "title",            limit: 255
    t.string   "name",             limit: 255
    t.text     "description",      limit: 65535
    t.string   "photo",            limit: 255
    t.string   "google_plus_link", limit: 255
    t.string   "twitter_handle",   limit: 255
    t.string   "slug",             limit: 255
    t.integer  "articles_count",   limit: 4,     default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "article_authors", ["name"], name: "index_article_authors_on_name", using: :btree
  add_index "article_authors", ["slug"], name: "index_article_authors_on_slug", using: :btree

  create_table "article_categories", force: :cascade do |t|
    t.string   "name",           limit: 255
    t.string   "slug",           limit: 255
    t.integer  "articles_count", limit: 4,   default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "article_categories", ["name"], name: "index_article_categories_on_name", using: :btree
  add_index "article_categories", ["slug"], name: "index_article_categories_on_slug", using: :btree

  create_table "articles", force: :cascade do |t|
    t.string   "title",               limit: 255
    t.text     "short",               limit: 65535
    t.text     "full",                limit: 65535
    t.string   "image",               limit: 255
    t.boolean  "frontpage",           limit: 1,     default: false
    t.boolean  "live",                limit: 1,     default: false
    t.string   "slug",                limit: 255
    t.integer  "article_category_id", limit: 4
    t.integer  "article_author_id",   limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "articles", ["article_author_id"], name: "index_articles_on_article_author_id", using: :btree
  add_index "articles", ["article_category_id"], name: "index_articles_on_article_category_id", using: :btree
  add_index "articles", ["slug"], name: "index_articles_on_slug", using: :btree

  create_table "boat_categories", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.boolean  "active",     limit: 1,   default: false
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
  end

  add_index "boat_categories", ["active"], name: "index_boat_categories_on_active", using: :btree
  add_index "boat_categories", ["name"], name: "index_boat_categories_on_name", using: :btree

  create_table "boat_images", force: :cascade do |t|
    t.string   "source_ref",         limit: 255
    t.string   "source_url",         limit: 255
    t.string   "file",               limit: 255
    t.integer  "position",           limit: 4
    t.datetime "http_last_modified"
    t.integer  "boat_id",            limit: 4
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.datetime "deleted_at"
    t.integer  "width",              limit: 4
    t.integer  "height",             limit: 4
  end

  add_index "boat_images", ["boat_id"], name: "index_boat_images_on_boat_id", using: :btree
  add_index "boat_images", ["position"], name: "index_boat_images_on_position", using: :btree
  add_index "boat_images", ["source_url"], name: "index_boat_images_on_source_url", using: :btree

  create_table "boat_specifications", force: :cascade do |t|
    t.integer  "specification_id", limit: 4
    t.integer  "boat_id",          limit: 4
    t.string   "value",            limit: 255
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.datetime "deleted_at"
  end

  add_index "boat_specifications", ["boat_id"], name: "index_boat_specifications_on_boat_id", using: :btree
  add_index "boat_specifications", ["specification_id"], name: "index_boat_specifications_on_specification_id", using: :btree

  create_table "boat_types", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.boolean  "active",     limit: 1,   default: false
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
  end

  add_index "boat_types", ["active"], name: "index_boat_types_on_active", using: :btree
  add_index "boat_types", ["name"], name: "index_boat_types_on_name", using: :btree

  create_table "boats", force: :cascade do |t|
    t.string   "name",                   limit: 255
    t.datetime "deleted_at"
    t.boolean  "new_boat",               limit: 1,     default: false
    t.boolean  "featured",               limit: 1
    t.boolean  "recently_reduced",       limit: 1
    t.boolean  "poa",                    limit: 1
    t.boolean  "under_offer",            limit: 1
    t.string   "source_id",              limit: 255
    t.string   "source_url",             limit: 512
    t.string   "location",               limit: 255
    t.string   "geo_location",           limit: 255
    t.integer  "year_built",             limit: 4
    t.float    "price",                  limit: 24
    t.float    "length_m",               limit: 24
    t.string   "slug",                   limit: 255
    t.text     "description",            limit: 65535
    t.text     "owners_comment",         limit: 65535
    t.integer  "user_id",                limit: 4
    t.integer  "boat_type_id",           limit: 4
    t.integer  "import_id",              limit: 4
    t.integer  "office_id",              limit: 4
    t.integer  "manufacturer_id",        limit: 4
    t.integer  "model_id",               limit: 4
    t.integer  "country_id",             limit: 4
    t.integer  "currency_id",            limit: 4
    t.integer  "drive_type_id",          limit: 4
    t.integer  "engine_manufacturer_id", limit: 4
    t.integer  "engine_model_id",        limit: 4
    t.integer  "vat_rate_id",            limit: 4
    t.integer  "fuel_type_id",           limit: 4
    t.datetime "created_at",                                           null: false
    t.datetime "updated_at",                                           null: false
    t.integer  "category_id",            limit: 4
  end

  add_index "boats", ["boat_type_id"], name: "index_boats_on_boat_type_id", using: :btree
  add_index "boats", ["country_id"], name: "index_boats_on_country_id", using: :btree
  add_index "boats", ["currency_id"], name: "index_boats_on_currency_id", using: :btree
  add_index "boats", ["drive_type_id"], name: "index_boats_on_drive_type_id", using: :btree
  add_index "boats", ["engine_manufacturer_id"], name: "index_boats_on_engine_manufacturer_id", using: :btree
  add_index "boats", ["engine_model_id"], name: "index_boats_on_engine_model_id", using: :btree
  add_index "boats", ["featured"], name: "index_boats_on_featured", using: :btree
  add_index "boats", ["fuel_type_id"], name: "index_boats_on_fuel_type_id", using: :btree
  add_index "boats", ["import_id"], name: "index_boats_on_import_id", using: :btree
  add_index "boats", ["manufacturer_id"], name: "index_boats_on_manufacturer_id", using: :btree
  add_index "boats", ["model_id"], name: "index_boats_on_model_id", using: :btree
  add_index "boats", ["office_id"], name: "index_boats_on_office_id", using: :btree
  add_index "boats", ["slug"], name: "index_boats_on_slug", using: :btree
  add_index "boats", ["source_id"], name: "index_boats_on_source_id", using: :btree
  add_index "boats", ["user_id"], name: "index_boats_on_user_id", using: :btree
  add_index "boats", ["vat_rate_id"], name: "index_boats_on_vat_rate_id", using: :btree

  create_table "buyer_guides", force: :cascade do |t|
    t.integer  "article_author_id", limit: 4
    t.integer  "manufacturer_id",   limit: 4
    t.integer  "model_id",          limit: 4
    t.string   "slug",              limit: 255
    t.text     "body",              limit: 65535
    t.string   "short_description", limit: 255
    t.text     "zcard_desc",        limit: 65535
    t.string   "photo",             limit: 255
    t.string   "thumbnail",         limit: 255
    t.boolean  "published",         limit: 1,     default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "buyer_guides", ["article_author_id"], name: "index_buyer_guides_on_article_author_id", using: :btree
  add_index "buyer_guides", ["manufacturer_id"], name: "index_buyer_guides_on_manufacturer_id", using: :btree
  add_index "buyer_guides", ["model_id"], name: "index_buyer_guides_on_model_id", using: :btree
  add_index "buyer_guides", ["slug"], name: "index_buyer_guides_on_slug", using: :btree

  create_table "countries", force: :cascade do |t|
    t.string   "iso",          limit: 255
    t.string   "name",         limit: 255
    t.string   "slug",         limit: 255
    t.text     "description",  limit: 65535
    t.integer  "currency_id",  limit: 4
    t.boolean  "active",       limit: 1,     default: false
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
    t.string   "country_code", limit: 255
  end

  add_index "countries", ["active"], name: "index_countries_on_active", using: :btree
  add_index "countries", ["currency_id"], name: "index_countries_on_currency_id", using: :btree
  add_index "countries", ["iso"], name: "index_countries_on_iso", using: :btree
  add_index "countries", ["slug"], name: "index_countries_on_slug", using: :btree

  create_table "currencies", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.float    "rate",       limit: 24,  default: 1.0
    t.string   "symbol",     limit: 255
    t.boolean  "active",     limit: 1
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
    t.integer  "position",   limit: 4
  end

  add_index "currencies", ["name"], name: "index_currencies_on_name", using: :btree

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",   limit: 4,     default: 0, null: false
    t.integer  "attempts",   limit: 4,     default: 0, null: false
    t.text     "handler",    limit: 65535,             null: false
    t.text     "last_error", limit: 65535
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by",  limit: 255
    t.string   "queue",      limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

  create_table "drive_types", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.boolean  "active",     limit: 1,   default: false
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
  end

  add_index "drive_types", ["active"], name: "index_drive_types_on_active", using: :btree
  add_index "drive_types", ["name"], name: "index_drive_types_on_name", using: :btree

  create_table "engine_manufacturers", force: :cascade do |t|
    t.string   "name",         limit: 255
    t.string   "display_name", limit: 255
    t.boolean  "active",       limit: 1,   default: false
    t.datetime "created_at",                               null: false
    t.datetime "updated_at",                               null: false
  end

  add_index "engine_manufacturers", ["active"], name: "index_engine_manufacturers_on_active", using: :btree
  add_index "engine_manufacturers", ["name"], name: "index_engine_manufacturers_on_name", using: :btree

  create_table "engine_models", force: :cascade do |t|
    t.string   "name",                   limit: 255
    t.integer  "engine_manufacturer_id", limit: 4
    t.boolean  "active",                 limit: 1,   default: false
    t.datetime "created_at",                                         null: false
    t.datetime "updated_at",                                         null: false
  end

  add_index "engine_models", ["active"], name: "index_engine_models_on_active", using: :btree
  add_index "engine_models", ["engine_manufacturer_id"], name: "index_engine_models_on_engine_manufacturer_id", using: :btree
  add_index "engine_models", ["name"], name: "index_engine_models_on_name", using: :btree

  create_table "enquiries", force: :cascade do |t|
    t.integer  "user_id",      limit: 4
    t.integer  "boat_id",      limit: 4
    t.string   "title",        limit: 255
    t.string   "first_name",   limit: 255
    t.string   "surname",      limit: 255
    t.string   "email",        limit: 255
    t.string   "phone",        limit: 255
    t.text     "message",      limit: 65535
    t.string   "remote_ip",    limit: 255
    t.string   "browser",      limit: 255
    t.string   "token",        limit: 64
    t.datetime "deleted_at"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.string   "country_code", limit: 255
  end

  add_index "enquiries", ["boat_id"], name: "index_enquiries_on_boat_id", using: :btree
  add_index "enquiries", ["token"], name: "index_enquiries_on_token", using: :btree
  add_index "enquiries", ["user_id"], name: "index_enquiries_on_user_id", using: :btree

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.string   "slug",           limit: 255, null: false
    t.integer  "sluggable_id",   limit: 4,   null: false
    t.string   "sluggable_type", limit: 50
    t.string   "scope",          limit: 255
    t.datetime "created_at"
  end

  add_index "friendly_id_slugs", ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true, using: :btree
  add_index "friendly_id_slugs", ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type", using: :btree
  add_index "friendly_id_slugs", ["sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_id", using: :btree
  add_index "friendly_id_slugs", ["sluggable_type"], name: "index_friendly_id_slugs_on_sluggable_type", using: :btree

  create_table "fuel_types", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.boolean  "active",     limit: 1,   default: false
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
  end

  add_index "fuel_types", ["active"], name: "index_fuel_types_on_active", using: :btree
  add_index "fuel_types", ["name"], name: "index_fuel_types_on_name", using: :btree

  create_table "imports", force: :cascade do |t|
    t.integer  "user_id",            limit: 4
    t.text     "param",              limit: 65535
    t.datetime "last_ran_at"
    t.boolean  "active",             limit: 1
    t.integer  "threads",            limit: 4,     default: 1
    t.string   "import_type",        limit: 255
    t.datetime "created_at",                                       null: false
    t.datetime "updated_at",                                       null: false
    t.boolean  "use_proxy",          limit: 1,     default: false
    t.string   "frequency_unit",     limit: 16,    default: "1"
    t.integer  "frequency_quantity", limit: 4
    t.string   "at",                 limit: 64
    t.integer  "pid",                limit: 4
    t.datetime "queued_at"
    t.string   "tz",                 limit: 255
    t.integer  "total_count",        limit: 4,     default: 0
    t.integer  "new_count",          limit: 4,     default: 0
    t.integer  "updated_count",      limit: 4,     default: 0
    t.integer  "deleted_count",      limit: 4,     default: 0
    t.string   "error_msg",          limit: 255
  end

  add_index "imports", ["user_id"], name: "index_imports_on_user_id", using: :btree

  create_table "mail_subscriptions", force: :cascade do |t|
    t.string   "email",      limit: 255
    t.boolean  "active",     limit: 1
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "manufacturers", force: :cascade do |t|
    t.string   "name",        limit: 255
    t.text     "description", limit: 65535
    t.string   "weburl",      limit: 512
    t.string   "logo",        limit: 255
    t.string   "slug",        limit: 255
    t.boolean  "active",      limit: 1,     default: false
    t.datetime "created_at",                                null: false
    t.datetime "updated_at",                                null: false
  end

  add_index "manufacturers", ["active"], name: "index_manufacturers_on_active", using: :btree
  add_index "manufacturers", ["name"], name: "index_manufacturers_on_name", using: :btree
  add_index "manufacturers", ["slug"], name: "index_manufacturers_on_slug", using: :btree

  create_table "marine_enquiries", force: :cascade do |t|
    t.string   "title",        limit: 255
    t.string   "first_name",   limit: 255
    t.string   "last_name",    limit: 255
    t.string   "email",        limit: 255
    t.string   "enquiry_type", limit: 255
    t.string   "country_code", limit: 255
    t.string   "phone",        limit: 255
    t.text     "comments",     limit: 65535
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  create_table "misspellings", force: :cascade do |t|
    t.integer  "source_id",    limit: 4
    t.string   "source_type",  limit: 255
    t.string   "alias_string", limit: 255
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  add_index "misspellings", ["source_type", "source_id"], name: "index_misspellings_on_source_type_and_source_id", using: :btree
  add_index "misspellings", ["source_type"], name: "index_misspellings_on_source_type", using: :btree

  create_table "models", force: :cascade do |t|
    t.string   "name",            limit: 255
    t.integer  "manufacturer_id", limit: 4
    t.string   "slug",            limit: 255
    t.boolean  "active",          limit: 1,   default: false
    t.boolean  "sailing",         limit: 1,   default: false
    t.datetime "created_at",                                  null: false
    t.datetime "updated_at",                                  null: false
  end

  add_index "models", ["active"], name: "index_models_on_active", using: :btree
  add_index "models", ["manufacturer_id"], name: "index_models_on_manufacturer_id", using: :btree
  add_index "models", ["name"], name: "index_models_on_name", using: :btree
  add_index "models", ["sailing"], name: "index_models_on_sailing", using: :btree
  add_index "models", ["slug"], name: "index_models_on_slug", using: :btree

  create_table "offices", force: :cascade do |t|
    t.string   "name",          limit: 255
    t.string   "contact_name",  limit: 255
    t.string   "daytime_phone", limit: 255
    t.string   "evening_phone", limit: 255
    t.string   "mobile",        limit: 255
    t.string   "fax",           limit: 255
    t.string   "email",         limit: 255
    t.string   "website",       limit: 255
    t.integer  "user_id",       limit: 4
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  add_index "offices", ["name"], name: "index_offices_on_name", using: :btree
  add_index "offices", ["user_id"], name: "index_offices_on_user_id", using: :btree

  create_table "saved_boats", force: :cascade do |t|
    t.integer  "user_id",    limit: 4
    t.integer  "boat_id",    limit: 4
    t.datetime "created_at"
    t.datetime "deleted_at"
  end

  add_index "saved_boats", ["user_id", "boat_id"], name: "index_saved_boats_on_user_id_and_boat_id", unique: true, using: :btree

  create_table "specifications", force: :cascade do |t|
    t.string   "name",         limit: 255
    t.string   "display_name", limit: 255
    t.integer  "position",     limit: 4
    t.boolean  "active",       limit: 1,   default: false
    t.datetime "created_at",                               null: false
    t.datetime "updated_at",                               null: false
    t.boolean  "visible",      limit: 1
  end

  add_index "specifications", ["active"], name: "index_specifications_on_active", using: :btree
  add_index "specifications", ["name"], name: "index_specifications_on_name", using: :btree

  create_table "subscriptions", force: :cascade do |t|
    t.string   "name",        limit: 255
    t.string   "description", limit: 255
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  add_index "subscriptions", ["name"], name: "index_subscriptions_on_name", unique: true, using: :btree

  create_table "subscriptions_users", force: :cascade do |t|
    t.integer "user_id",         limit: 4
    t.integer "subscription_id", limit: 4
  end

  add_index "subscriptions_users", ["user_id", "subscription_id"], name: "index_subscriptions_users_on_user_id_and_subscription_id", unique: true, using: :btree

  create_table "user_informations", force: :cascade do |t|
    t.integer "user_id",            limit: 4
    t.boolean "require_finance",    limit: 1, default: false
    t.boolean "list_boat_for_sale", limit: 1, default: false
    t.boolean "buy_this_season",    limit: 1, default: false
    t.boolean "looking_for_berth",  limit: 1, default: false
  end

  add_index "user_informations", ["user_id"], name: "index_user_informations_on_user_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "email",                  limit: 255,   default: "", null: false
    t.string   "encrypted_password",     limit: 255,   default: "", null: false
    t.string   "reset_password_token",   limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          limit: 4,     default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",     limit: 255
    t.string   "last_sign_in_ip",        limit: 255
    t.string   "title",                  limit: 255
    t.integer  "role",                   limit: 4,     default: 0
    t.string   "first_name",             limit: 255
    t.string   "last_name",              limit: 255
    t.string   "username",               limit: 255
    t.string   "phone",                  limit: 255
    t.string   "fax",                    limit: 255
    t.string   "mobile",                 limit: 255
    t.string   "security_question",      limit: 255
    t.string   "security_answer",        limit: 255
    t.string   "avatar",                 limit: 255
    t.text     "description",            limit: 65535
    t.string   "company_name",           limit: 255
    t.string   "company_weburl",         limit: 255
    t.text     "company_description",    limit: 65535
    t.string   "slug",                   limit: 255
    t.datetime "created_at",                                        null: false
    t.datetime "updated_at",                                        null: false
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", ["role"], name: "index_users_on_role", using: :btree
  add_index "users", ["slug"], name: "index_users_on_slug", using: :btree
  add_index "users", ["username"], name: "index_users_on_username", using: :btree

  create_table "vat_rates", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.boolean  "active",     limit: 1,   default: false
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
  end

  add_index "vat_rates", ["active"], name: "index_vat_rates_on_active", using: :btree
  add_index "vat_rates", ["name"], name: "index_vat_rates_on_name", using: :btree

  add_foreign_key "addresses", "countries"
  add_foreign_key "articles", "article_authors"
  add_foreign_key "articles", "article_categories"
  add_foreign_key "boat_images", "boats"
  add_foreign_key "boat_specifications", "boats"
  add_foreign_key "boat_specifications", "specifications"
  add_foreign_key "boats", "boat_types"
  add_foreign_key "boats", "countries"
  add_foreign_key "boats", "currencies"
  add_foreign_key "boats", "drive_types"
  add_foreign_key "boats", "engine_manufacturers"
  add_foreign_key "boats", "engine_models"
  add_foreign_key "boats", "fuel_types"
  add_foreign_key "boats", "imports"
  add_foreign_key "boats", "manufacturers"
  add_foreign_key "boats", "models"
  add_foreign_key "boats", "offices"
  add_foreign_key "boats", "users"
  add_foreign_key "boats", "vat_rates"
  add_foreign_key "countries", "currencies"
  add_foreign_key "engine_models", "engine_manufacturers"
  add_foreign_key "enquiries", "boats"
  add_foreign_key "enquiries", "users"
  add_foreign_key "imports", "users"
  add_foreign_key "models", "manufacturers"
  add_foreign_key "offices", "users"
end
