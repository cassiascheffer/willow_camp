class AddRequiredFieldsToPost < ActiveRecord::Migration[8.0]
  def change
    add_column :posts, :slug, :string, null: false
  end
end
