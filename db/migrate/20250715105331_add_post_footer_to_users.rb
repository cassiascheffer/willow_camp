class AddPostFooterToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :post_footer_markdown, :text
    add_column :users, :post_footer_html, :text
  end
end
