class CreateUserToken < ActiveRecord::Migration[8.0]
  def change
    create_table :user_tokens do |t|
      t.string :token, null: false
      t.references :user, null: false, foreign_key: true
      t.datetime :expires_at
      t.string :name
      t.timestamps
    end
  end
end
