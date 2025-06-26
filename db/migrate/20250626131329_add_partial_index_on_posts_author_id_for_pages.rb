class AddPartialIndexOnPostsAuthorIdForPages < ActiveRecord::Migration[8.0]
  def change
    add_index :posts, :author_id, where: "type = 'Page'", name: "index_posts_on_author_id_pages_only"
  end
end
