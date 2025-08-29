class AddPrimaryToBlogs < ActiveRecord::Migration[8.0]
  def change
    add_column :blogs, :primary, :boolean, default: false, null: false
  end
end
