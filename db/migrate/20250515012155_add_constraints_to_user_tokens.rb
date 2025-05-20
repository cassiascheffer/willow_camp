class AddConstraintsToUserTokens < ActiveRecord::Migration[8.0]
  def up
    # Add NOT NULL constraint to name column
    change_column_null :user_tokens, :name, false

    # Add CHECK constraint to ensure expires_at is in the future when not null
    execute <<-SQL
      ALTER TABLE user_tokens#{" "}
      ADD CONSTRAINT check_expires_at_in_future#{" "}
      CHECK (expires_at IS NULL OR expires_at > CURRENT_TIMESTAMP)
    SQL
  end

  def down
    # Remove CHECK constraint
    execute <<-SQL
      ALTER TABLE user_tokens
      DROP CONSTRAINT IF EXISTS check_expires_at_in_future
    SQL

    # Remove NOT NULL constraint from name column
    change_column_null :user_tokens, :name, true
  end
end
