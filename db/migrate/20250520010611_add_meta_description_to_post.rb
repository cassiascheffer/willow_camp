class AddMetaDescriptionToPost < ActiveRecord::Migration[8.0]
  def change
    add_column :posts, :meta_description, :string, limit: 160
  end
end
