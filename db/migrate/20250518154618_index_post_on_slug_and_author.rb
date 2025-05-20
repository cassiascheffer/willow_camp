class IndexPostOnSlugAndAuthor < ActiveRecord::Migration[8.0]
  def change
    remove_index :posts, :slug, if_exists: true
    remove_index :posts, :author_id, if_exists: true
    add_index :posts, [:slug, :author_id], unique: true, name: "index_posts_on_slug_and_author"
  end
end
