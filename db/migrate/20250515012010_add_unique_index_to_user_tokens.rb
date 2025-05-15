class AddUniqueIndexToUserTokens < ActiveRecord::Migration[8.0]
  def change
    add_index :user_tokens, :token, unique: true
  end
end
