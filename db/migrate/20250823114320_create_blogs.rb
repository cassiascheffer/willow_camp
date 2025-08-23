class CreateBlogs < ActiveRecord::Migration[8.0]
  def change
    create_table :blogs, id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.uuid :user_id, null: false
      t.string :subdomain
      t.string :title
      t.string :slug
      t.text :meta_description
      t.string :favicon_emoji
      t.string :custom_domain
      t.string :theme, default: "light"
      t.text :post_footer_markdown
      t.text :post_footer_html
      t.boolean :no_index, default: false, null: false

      t.timestamps
    end

    add_index :blogs, :user_id
    add_index :blogs, :subdomain, unique: true
    add_index :blogs, :slug, unique: true
    add_index :blogs, :custom_domain, unique: true
    add_foreign_key :blogs, :users
  end
end
