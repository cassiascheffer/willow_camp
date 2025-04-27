class AddIndexToPostsSlug < ActiveRecord::Migration[8.0]
  def change
    add_index :posts, :slug, unique: true
  end
end
