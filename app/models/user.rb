class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :posts, foreign_key: "author_id", dependent: :destroy
  has_many :tokens, class_name: "UserToken", dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  normalizes :subdomain, with: ->(s) { s.strip.downcase }

  # Email validations
  validates :email_address, presence: true,
                           uniqueness: true,
                           format: { with: URI::MailTo::EMAIL_REGEXP, message: "must be a valid email address" }

  # Subdomain validations
  validates :subdomain, presence: true,
                       uniqueness: true,
                       format: { with: /\A[a-z0-9\-_]+\z/, message: "may only contain letters, numbers, hyphens and underscores" },
                       length: { minimum: 3, maximum: 63 }

  # Password validations
  validates :password, presence: true, length: { minimum: 6 }, allow_nil: true

  # Name and blog_title validations
  validates :name, presence: true, length: { maximum: 255 }, allow_blank: true
  validates :blog_title, length: { maximum: 255 }, allow_blank: true
end
