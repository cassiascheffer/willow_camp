class ChangePostBody < ActiveRecord::Migration[8.0]
  def change
    remove_column :posts, :body, :text
    add_column :posts, :body_markdown, :text
    add_column :posts, :body_html, :text
  end
end
