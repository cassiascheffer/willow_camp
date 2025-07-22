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

ActiveRecord::Schema[8.0].define(version: 2025_07_22_112259) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "friendly_id_slugs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "slug", null: false
    t.string "sluggable_type", limit: 50
    t.string "scope"
    t.datetime "created_at"
    t.uuid "sluggable_id"
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_sluggable_type_scope_uuid", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_id", "sluggable_type"], name: "index_friendly_id_slugs_on_sluggable_uuid_and_sluggable_type"
  end

  create_table "posts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "title"
    t.boolean "published"
    t.datetime "published_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "body_markdown"
    t.text "body_html"
    t.string "slug"
    t.string "meta_description"
    t.uuid "author_id", null: false
    t.string "type"
    t.boolean "has_mermaid_diagrams", default: false, null: false
    t.index ["author_id"], name: "index_posts_on_author_id_pages_only", where: "((type)::text = 'Page'::text)"
    t.index ["author_id"], name: "index_posts_on_author_uuid"
    t.index ["slug", "author_id"], name: "index_posts_on_slug_and_author_uuid", unique: true
    t.index ["type"], name: "index_posts_on_type"
  end

  create_table "taggings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "taggable_type"
    t.string "tagger_type"
    t.string "context", limit: 128
    t.datetime "created_at", precision: nil
    t.string "tenant", limit: 128
    t.uuid "tag_id"
    t.uuid "taggable_id"
    t.uuid "tagger_id"
    t.index ["context"], name: "index_taggings_on_context"
    t.index ["tag_id"], name: "index_taggings_on_tag_uuid"
    t.index ["taggable_id", "taggable_type"], name: "index_taggings_on_taggable_uuid_and_taggable_type"
    t.index ["taggable_type"], name: "index_taggings_on_taggable_type"
    t.index ["tagger_id", "tagger_type"], name: "index_taggings_on_tagger_uuid_and_tagger_type"
    t.index ["tenant"], name: "index_taggings_on_tenant"
  end

  create_table "tags", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "taggings_count", default: 0
    t.string "slug"
    t.index ["name"], name: "index_tags_on_name", unique: true
    t.index ["slug"], name: "index_tags_on_slug", unique: true
  end

  create_table "user_tokens", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "token", null: false
    t.datetime "expires_at"
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["token"], name: "index_user_tokens_on_token", unique: true
    t.index ["user_id"], name: "index_user_tokens_on_user_uuid"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email", null: false
    t.string "encrypted_password", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "subdomain"
    t.string "name"
    t.string "blog_title"
    t.string "token"
    t.datetime "token_expires_at", precision: nil
    t.string "slug"
    t.text "site_meta_description"
    t.string "favicon_emoji"
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "custom_domain"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.string "theme", default: "light"
    t.text "post_footer_markdown"
    t.text "post_footer_html"
    t.boolean "no_index", default: false, null: false
    t.index ["custom_domain"], name: "index_users_on_custom_domain", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["slug"], name: "index_users_on_slug", unique: true
    t.index ["subdomain"], name: "index_users_on_subdomain", unique: true
  end

  add_foreign_key "posts", "users", column: "author_id"
  add_foreign_key "taggings", "tags"
  add_foreign_key "user_tokens", "users"
end
