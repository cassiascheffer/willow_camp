class AddSubdomainToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :subdomain, :string, null: false
    add_index :users, :subdomain, unique: true
  end
end
