class CleanUpTablesAfterUuidMigration < ActiveRecord::Migration[8.0]
  def up
    # Create new ID columns and update application to use them

    # For all tables, make UUID the official ID by:
    # 1. Dropping the integer ID column
    # 2. Renaming UUID columns to standard names

    # Update users table
    execute <<-SQL
      ALTER TABLE users RENAME COLUMN id TO integer_id;
      ALTER TABLE users RENAME COLUMN uuid TO id;
    SQL

    # Update posts table
    execute <<-SQL
      ALTER TABLE posts RENAME COLUMN id TO integer_id;
      ALTER TABLE posts RENAME COLUMN uuid TO id;
      ALTER TABLE posts RENAME COLUMN author_id TO author_integer_id;
      ALTER TABLE posts RENAME COLUMN author_uuid TO author_id;
    SQL

    # Update sessions table
    execute <<-SQL
      ALTER TABLE sessions RENAME COLUMN id TO integer_id;
      ALTER TABLE sessions RENAME COLUMN uuid TO id;
      ALTER TABLE sessions RENAME COLUMN user_id TO user_integer_id;
      ALTER TABLE sessions RENAME COLUMN user_uuid TO user_id;
    SQL

    # Update user_tokens table
    execute <<-SQL
      ALTER TABLE user_tokens RENAME COLUMN id TO integer_id;
      ALTER TABLE user_tokens RENAME COLUMN uuid TO id;
      ALTER TABLE user_tokens RENAME COLUMN user_id TO user_integer_id;
      ALTER TABLE user_tokens RENAME COLUMN user_uuid TO user_id;
    SQL

    # Update tags table
    execute <<-SQL
      ALTER TABLE tags RENAME COLUMN id TO integer_id;
      ALTER TABLE tags RENAME COLUMN uuid TO id;
    SQL

    # Update taggings table
    execute <<-SQL
      ALTER TABLE taggings RENAME COLUMN id TO integer_id;
      ALTER TABLE taggings RENAME COLUMN uuid TO id;
      ALTER TABLE taggings RENAME COLUMN tag_id TO tag_integer_id;
      ALTER TABLE taggings RENAME COLUMN tag_uuid TO tag_id;
      ALTER TABLE taggings RENAME COLUMN taggable_id TO taggable_integer_id;
      ALTER TABLE taggings RENAME COLUMN taggable_uuid TO taggable_id;
      ALTER TABLE taggings RENAME COLUMN tagger_id TO tagger_integer_id;
      ALTER TABLE taggings RENAME COLUMN tagger_uuid TO tagger_id;
    SQL

    # Update friendly_id_slugs table
    execute <<-SQL
      ALTER TABLE friendly_id_slugs RENAME COLUMN id TO integer_id;
      ALTER TABLE friendly_id_slugs RENAME COLUMN uuid TO id;
      ALTER TABLE friendly_id_slugs RENAME COLUMN sluggable_id TO sluggable_integer_id;
      ALTER TABLE friendly_id_slugs RENAME COLUMN sluggable_uuid TO sluggable_id;
    SQL

    # Reset the primary key sequences to use UUID generation
    execute <<-SQL
      ALTER TABLE users ALTER COLUMN id SET DEFAULT gen_random_uuid();
      ALTER TABLE posts ALTER COLUMN id SET DEFAULT gen_random_uuid();
      ALTER TABLE sessions ALTER COLUMN id SET DEFAULT gen_random_uuid();
      ALTER TABLE user_tokens ALTER COLUMN id SET DEFAULT gen_random_uuid();
      ALTER TABLE tags ALTER COLUMN id SET DEFAULT gen_random_uuid();
      ALTER TABLE taggings ALTER COLUMN id SET DEFAULT gen_random_uuid();
      ALTER TABLE friendly_id_slugs ALTER COLUMN id SET DEFAULT gen_random_uuid();
    SQL
  end

  def down
    # This migration is not reversible
    raise ActiveRecord::IrreversibleMigration
  end
end
