class AddBlogTitleToUser < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :blog_title, :string
  end
end
