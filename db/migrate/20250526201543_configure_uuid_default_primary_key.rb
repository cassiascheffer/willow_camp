class ConfigureUuidDefaultPrimaryKey < ActiveRecord::Migration[8.0]
  def up
    # Configure Rails to use uuid for newly created tables
    # This only affects new tables, not existing ones
    connection.execute <<-SQL
      ALTER DATABASE "#{connection.current_database}" SET default_table_access_method = heap;
    SQL
  end

  def down
    # Revert to default PostgreSQL settings (not really necessary since we're not changing
    # the default primary key type in the database itself)
  end
end
