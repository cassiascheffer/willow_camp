class AddNoIndexToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :no_index, :boolean, default: false, null: false
  end
end
