class AddBlogsCountToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :blogs_count, :integer, default: 0, null: false
  end
end
