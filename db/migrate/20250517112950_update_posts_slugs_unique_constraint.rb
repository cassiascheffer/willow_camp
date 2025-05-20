class UpdatePostsSlugsUniqueConstraint < ActiveRecord::Migration[8.0]
  def change
    # Remove existing unique index on slug
    remove_index :posts, :slug, name: "index_posts_on_slug", unique: true

    # Add new index with slug scoped to author_id
    add_index :posts, [:author_id, :slug], unique: true, name: "index_posts_on_author_id_and_slug"
  end
end
