class CleanUpUserSlugs < ActiveRecord::Migration[8.0]
  def change
    remove_column :posts, :slug, :string
    remove_column :posts, :base_slug, :string
    remove_column :posts, :slug_suffix, :string
  end
end
