class AddBlogToPosts < ActiveRecord::Migration[8.0]
  def change
    # Add blog_id column to posts table
    add_reference :posts, :blog, type: :uuid, foreign_key: true, index: true

    # Note: Unique constraint will be added in a subsequent migration
    # to handle backwards compatibility with nil blog_id
  end
end
