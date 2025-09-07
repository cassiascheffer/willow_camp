class User < ApplicationRecord
  # Devise modules
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :trackable, :validatable

  # Associations
  has_many :blogs, dependent: :destroy
  has_many :posts, foreign_key: "author_id", dependent: :destroy, inverse_of: :author
  has_many :pages, foreign_key: "author_id", dependent: :destroy, inverse_of: :author
  has_many :tokens, class_name: "UserToken", dependent: :destroy

  # Validations
  validates :name, presence: true, length: {maximum: 255}, allow_blank: true
end
