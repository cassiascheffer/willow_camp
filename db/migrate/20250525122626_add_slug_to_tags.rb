class AddSlugToTags < ActiveRecord::Migration[8.0]
  def up
    add_column :tags, :slug, :string
    add_index :tags, :slug, unique: true

    # Generate slugs for existing tags
    if defined?(ActsAsTaggableOn::Tag)
      ActsAsTaggableOn::Tag.all.find_each do |tag|
        tag.slug = nil # Force friendly_id to regenerate the slug
        tag.save
      end
    end
  end

  def down
    remove_index :tags, :slug
    remove_column :tags, :slug
  end
end
