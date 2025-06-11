class AllowNullSubdomainInUsers < ActiveRecord::Migration[8.0]
  def change
    change_column_null :users, :subdomain, true
  end
end
