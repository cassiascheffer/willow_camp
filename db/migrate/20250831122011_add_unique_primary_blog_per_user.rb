class AddUniquePrimaryBlogPerUser < ActiveRecord::Migration[8.0]
  def change
    # Add a unique partial index to ensure only one primary blog per user
    # The partial index only includes rows where primary = true
    add_index :blogs, [:user_id, :primary], 
              unique: true, 
              where: '"primary" = true',
              name: "index_blogs_on_user_id_primary_unique"
  end
end
