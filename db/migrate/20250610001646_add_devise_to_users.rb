class AddDeviseToUsers < ActiveRecord::Migration[8.0]
  def change
    # Rename existing columns to match Devise expectations
    rename_column :users, :email_address, :email
    rename_column :users, :password_digest, :encrypted_password

    # Add Devise columns that might be missing
    add_column :users, :reset_password_token, :string
    add_column :users, :reset_password_sent_at, :datetime
    add_column :users, :remember_created_at, :datetime
    add_column :users, :sign_in_count, :integer, default: 0, null: false
    add_column :users, :current_sign_in_at, :datetime
    add_column :users, :last_sign_in_at, :datetime
    add_column :users, :current_sign_in_ip, :string
    add_column :users, :last_sign_in_ip, :string

    # Add indexes for Devise
    add_index :users, :reset_password_token, unique: true

    # Update the existing email index name if needed
    remove_index :users, :email_address if index_exists?(:users, :email_address)
    add_index :users, :email, unique: true unless index_exists?(:users, :email)
  end
end
