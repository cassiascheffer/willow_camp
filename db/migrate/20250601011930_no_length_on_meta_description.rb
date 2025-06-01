class NoLengthOnMetaDescription < ActiveRecord::Migration[8.0]
  def up
    change_column :posts, :meta_description, :string, limit: nil
  end

  def down
    change_column :posts, :meta_description, :string, limit: 255
  end
end
