class RemoveIntegerIdColumns < ActiveRecord::Migration[8.0]
  def up
    remove_column :users, :integer_id
    remove_column :posts, :integer_id
    remove_column :posts, :author_integer_id
    remove_column :sessions, :integer_id
    remove_column :sessions, :user_integer_id
    remove_column :user_tokens, :integer_id
    remove_column :user_tokens, :user_integer_id
    remove_column :tags, :integer_id
    remove_column :taggings, :integer_id
    remove_column :taggings, :tag_integer_id
    remove_column :taggings, :taggable_integer_id
    remove_column :taggings, :tagger_integer_id
    remove_column :friendly_id_slugs, :integer_id
    remove_column :friendly_id_slugs, :sluggable_integer_id
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Cannot restore removed integer_id columns"
  end
end
