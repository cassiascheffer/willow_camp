class AddTypeToPosts < ActiveRecord::Migration[6.1]
  def change
    add_column :posts, :type, :string
    add_index :posts, :type
  end
end
