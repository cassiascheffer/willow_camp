class RevertToSingleTheme < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :theme, :string, default: "light"
    remove_column :users, :light_theme, :string
    remove_column :users, :dark_theme, :string
  end
end
