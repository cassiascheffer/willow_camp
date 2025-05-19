class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :posts, foreign_key: "author_id", dependent: :destroy
  has_many :tokens, class_name: "UserToken", dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }
end
