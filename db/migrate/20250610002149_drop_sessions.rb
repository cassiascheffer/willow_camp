class DropSessions < ActiveRecord::Migration[8.0]
  def change
    drop_table :sessions do |t|
      t.string "ip_address"
      t.string "user_agent"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.uuid "user_id", null: false
    end
  end
end
