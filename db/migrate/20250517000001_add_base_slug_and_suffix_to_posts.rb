class AddBaseSlugAndSuffixToPosts < ActiveRecord::Migration[8.0]
  def change
    add_column :posts, :base_slug, :string
    add_column :posts, :slug_suffix, :integer, default: 0

    # Index the base_slug for fast lookups
    add_index :posts, :base_slug

    # Compound index for faster lookups when searching by both
    add_index :posts, [:base_slug, :slug_suffix]
  end
end
