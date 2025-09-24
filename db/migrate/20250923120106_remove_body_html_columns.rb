class RemoveBodyHtmlColumns < ActiveRecord::Migration[8.0]
  def change
    remove_column :posts, :body_html, :text
    remove_column :blogs, :post_footer_html, :text
  end
end
