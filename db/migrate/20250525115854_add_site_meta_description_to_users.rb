class AddSiteMetaDescriptionToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :site_meta_description, :text
  end
end
