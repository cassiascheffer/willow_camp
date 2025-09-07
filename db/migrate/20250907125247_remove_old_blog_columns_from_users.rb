class RemoveOldBlogColumnsFromUsers < ActiveRecord::Migration[8.0]
  def change
    # Remove unique indexes first
    remove_index :users, :subdomain, if_exists: true
    remove_index :users, :slug, if_exists: true
    remove_index :users, :custom_domain, if_exists: true

    # Remove blog-related columns that are now handled by the blogs table
    remove_column :users, :subdomain, :string
    remove_column :users, :blog_title, :string
    remove_column :users, :slug, :string
    remove_column :users, :site_meta_description, :text
    remove_column :users, :favicon_emoji, :string
    remove_column :users, :custom_domain, :string
    remove_column :users, :theme, :string
    remove_column :users, :post_footer_markdown, :text
    remove_column :users, :post_footer_html, :text
    remove_column :users, :no_index, :boolean
  end
end
