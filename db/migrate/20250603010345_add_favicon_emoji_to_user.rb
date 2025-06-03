class AddFaviconEmojiToUser < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :favicon_emoji, :string
  end
end
