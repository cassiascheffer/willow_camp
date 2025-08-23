class UpdatePostsUniqueConstraint < ActiveRecord::Migration[8.0]
  def change
    # Remove the old author-based unique index
    remove_index :posts, name: "index_posts_on_slug_and_author_uuid" if index_exists?(:posts, [:slug, :author_id], name: "index_posts_on_slug_and_author_uuid")

    # Add new unique index that allows multiple blogs per user
    # This allows: same slug in different blogs, and nil blog_id for backwards compatibility
    # The constraint is: unique combination of slug + blog_id + author_id
    # This means:
    # - A user can have posts with same slug in different blogs
    # - Old posts without blog_id (nil) are still unique by slug + author_id
    # - New posts with blog_id are unique by slug + blog_id + author_id
    add_index :posts, [:slug, :blog_id, :author_id], unique: true, name: "index_posts_on_slug_blog_id_author_id"
  end
end
