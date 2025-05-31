class ConvertTablesFromIntegerIdToUuid < ActiveRecord::Migration[8.0]
  def up
    # Phase 1: Add UUID columns to all tables without making them primary keys yet

    # Users table
    add_column :users, :uuid, :uuid, default: "gen_random_uuid()", null: false

    # Posts table
    add_column :posts, :uuid, :uuid, default: "gen_random_uuid()", null: false
    add_column :posts, :author_uuid, :uuid

    # Sessions table
    add_column :sessions, :uuid, :uuid, default: "gen_random_uuid()", null: false
    add_column :sessions, :user_uuid, :uuid

    # User tokens table
    add_column :user_tokens, :uuid, :uuid, default: "gen_random_uuid()", null: false
    add_column :user_tokens, :user_uuid, :uuid

    # Tags table
    add_column :tags, :uuid, :uuid, default: "gen_random_uuid()", null: false

    # Taggings table (polymorphic)
    add_column :taggings, :uuid, :uuid, default: "gen_random_uuid()", null: false
    add_column :taggings, :tag_uuid, :uuid
    add_column :taggings, :taggable_uuid, :uuid
    add_column :taggings, :tagger_uuid, :uuid

    # Friendly ID slugs table
    add_column :friendly_id_slugs, :uuid, :uuid, default: "gen_random_uuid()", null: false
    add_column :friendly_id_slugs, :sluggable_uuid, :uuid

    # Phase 2: Create a mapping between old IDs and new UUIDs
    # This is necessary to update foreign keys

    # Create temporary tables to store the ID mappings
    create_table :_user_id_mapping, id: false do |t|
      t.bigint :old_id
      t.uuid :new_id
    end

    create_table :_post_id_mapping, id: false do |t|
      t.bigint :old_id
      t.uuid :new_id
    end

    create_table :_tag_id_mapping, id: false do |t|
      t.bigint :old_id
      t.uuid :new_id
    end

    # Store mappings
    execute <<-SQL
      INSERT INTO _user_id_mapping (old_id, new_id) 
      SELECT id, uuid FROM users;
      
      INSERT INTO _post_id_mapping (old_id, new_id) 
      SELECT id, uuid FROM posts;
      
      INSERT INTO _tag_id_mapping (old_id, new_id) 
      SELECT id, uuid FROM tags;
    SQL

    # Phase 3: Update foreign keys with UUID values

    # Update posts.author_uuid based on users.uuid mapping
    execute <<-SQL
      UPDATE posts
      SET author_uuid = _user_id_mapping.new_id
      FROM _user_id_mapping
      WHERE posts.author_id = _user_id_mapping.old_id;
    SQL

    # Update sessions.user_uuid
    execute <<-SQL
      UPDATE sessions
      SET user_uuid = _user_id_mapping.new_id
      FROM _user_id_mapping
      WHERE sessions.user_id = _user_id_mapping.old_id;
    SQL

    # Update user_tokens.user_uuid
    execute <<-SQL
      UPDATE user_tokens
      SET user_uuid = _user_id_mapping.new_id
      FROM _user_id_mapping
      WHERE user_tokens.user_id = _user_id_mapping.old_id;
    SQL

    # Update taggings.tag_uuid
    execute <<-SQL
      UPDATE taggings
      SET tag_uuid = _tag_id_mapping.new_id
      FROM _tag_id_mapping
      WHERE taggings.tag_id = _tag_id_mapping.old_id;
    SQL

    # Update taggings.taggable_uuid for posts
    execute <<-SQL
      UPDATE taggings
      SET taggable_uuid = _post_id_mapping.new_id
      FROM _post_id_mapping
      WHERE taggings.taggable_id = _post_id_mapping.old_id
      AND taggings.taggable_type = 'Post';
    SQL

    # Update taggings.tagger_uuid for users
    execute <<-SQL
      UPDATE taggings
      SET tagger_uuid = _user_id_mapping.new_id
      FROM _user_id_mapping
      WHERE taggings.tagger_id = _user_id_mapping.old_id
      AND taggings.tagger_type = 'User';
    SQL

    # Update friendly_id_slugs.sluggable_uuid
    # (handle different sluggable types separately)
    execute <<-SQL
      -- For User slugs
      UPDATE friendly_id_slugs
      SET sluggable_uuid = _user_id_mapping.new_id
      FROM _user_id_mapping
      WHERE friendly_id_slugs.sluggable_id = _user_id_mapping.old_id
      AND friendly_id_slugs.sluggable_type = 'User';
      
      -- For Post slugs
      UPDATE friendly_id_slugs
      SET sluggable_uuid = _post_id_mapping.new_id
      FROM _post_id_mapping
      WHERE friendly_id_slugs.sluggable_id = _post_id_mapping.old_id
      AND friendly_id_slugs.sluggable_type = 'Post';
      
      -- For Tag slugs
      UPDATE friendly_id_slugs
      SET sluggable_uuid = _tag_id_mapping.new_id
      FROM _tag_id_mapping
      WHERE friendly_id_slugs.sluggable_id = _tag_id_mapping.old_id
      AND friendly_id_slugs.sluggable_type = 'ActsAsTaggableOn::Tag';
    SQL

    # Phase 4: Create new indexes for UUID columns

    add_index :posts, :author_uuid
    add_index :posts, [:slug, :author_uuid], unique: true
    add_index :sessions, :user_uuid
    add_index :user_tokens, :user_uuid

    # Skip this index since it already exists
    # add_index :user_tokens, :token, unique: true
    # Create new indexes only if needed
    # We will conditionally create indexes to avoid conflicts

    execute <<-SQL
      -- Create index on taggings.tag_uuid
      DO $$
      BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'index_taggings_on_tag_uuid') THEN
          CREATE INDEX index_taggings_on_tag_uuid ON taggings(tag_uuid);
        END IF;
      END
      $$;

      -- Create index on taggings.taggable_uuid and taggable_type
      DO $$
      BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'index_taggings_on_taggable_uuid_and_taggable_type') THEN
          CREATE INDEX index_taggings_on_taggable_uuid_and_taggable_type ON taggings(taggable_uuid, taggable_type);
        END IF;
      END
      $$;

      -- Create index on taggings.tagger_uuid and tagger_type
      DO $$
      BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'index_taggings_on_tagger_uuid_and_tagger_type') THEN
          CREATE INDEX index_taggings_on_tagger_uuid_and_tagger_type ON taggings(tagger_uuid, tagger_type);
        END IF;
      END
      $$;

      -- Create index on friendly_id_slugs.sluggable_uuid and sluggable_type
      DO $$
      BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'index_friendly_id_slugs_on_sluggable_uuid_and_sluggable_type') THEN
          CREATE INDEX index_friendly_id_slugs_on_sluggable_uuid_and_sluggable_type ON friendly_id_slugs(sluggable_uuid, sluggable_type);
        END IF;
      END
      $$;

      -- Create unique index on friendly_id_slugs.slug, sluggable_type, and scope
      DO $$
      BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'index_friendly_id_slugs_on_slug_sluggable_type_scope_uuid') THEN
          CREATE UNIQUE INDEX index_friendly_id_slugs_on_slug_sluggable_type_scope_uuid ON friendly_id_slugs(slug, sluggable_type, scope);
        END IF;
      END
      $$;
    SQL

    # Phase 5: Make non-null constraints on foreign keys

    change_column_null :posts, :author_uuid, false
    change_column_null :sessions, :user_uuid, false
    change_column_null :user_tokens, :user_uuid, false

    # Phase 6: Change primary keys to use UUID columns

    # First, drop existing foreign key constraints
    remove_foreign_key :posts, :users, column: :author_id
    remove_foreign_key :sessions, :users
    remove_foreign_key :taggings, :tags
    remove_foreign_key :user_tokens, :users

    # For each table, drop old primary key and set new one
    # Users table
    execute <<-SQL
      ALTER TABLE users DROP CONSTRAINT users_pkey;
      ALTER TABLE users ADD PRIMARY KEY (uuid);
    SQL

    # Posts table
    execute <<-SQL
      ALTER TABLE posts DROP CONSTRAINT posts_pkey;
      ALTER TABLE posts ADD PRIMARY KEY (uuid);
    SQL

    # Sessions table
    execute <<-SQL
      ALTER TABLE sessions DROP CONSTRAINT sessions_pkey;
      ALTER TABLE sessions ADD PRIMARY KEY (uuid);
    SQL

    # User tokens table
    execute <<-SQL
      ALTER TABLE user_tokens DROP CONSTRAINT user_tokens_pkey;
      ALTER TABLE user_tokens ADD PRIMARY KEY (uuid);
    SQL

    # Tags table
    execute <<-SQL
      ALTER TABLE tags DROP CONSTRAINT tags_pkey;
      ALTER TABLE tags ADD PRIMARY KEY (uuid);
    SQL

    # Taggings table
    execute <<-SQL
      ALTER TABLE taggings DROP CONSTRAINT taggings_pkey;
      ALTER TABLE taggings ADD PRIMARY KEY (uuid);
    SQL

    # Friendly ID slugs table
    execute <<-SQL
      ALTER TABLE friendly_id_slugs DROP CONSTRAINT friendly_id_slugs_pkey;
      ALTER TABLE friendly_id_slugs ADD PRIMARY KEY (uuid);
    SQL

    # Phase 7: Set up new foreign key constraints using UUID

    add_foreign_key :posts, :users, column: :author_uuid, primary_key: :uuid
    add_foreign_key :sessions, :users, column: :user_uuid, primary_key: :uuid
    add_foreign_key :taggings, :tags, column: :tag_uuid, primary_key: :uuid
    add_foreign_key :user_tokens, :users, column: :user_uuid, primary_key: :uuid

    # We'll handle column renaming in a separate migration

    # Phase 9: Drop temporary mapping tables

    drop_table :_user_id_mapping
    drop_table :_post_id_mapping
    drop_table :_tag_id_mapping
  end

  def down
    # This migration is not reversible due to its complexity
    raise ActiveRecord::IrreversibleMigration
  end
end
