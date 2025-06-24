class AddThemePreferencesToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :light_theme, :string, default: "light"
    add_column :users, :dark_theme, :string, default: "dark"
  end
end
