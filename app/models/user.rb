class User < ApplicationRecord
  # Devise modules
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :trackable, :validatable

  # Associations
  has_many :posts, foreign_key: "author_id", dependent: :destroy, inverse_of: :author
  has_many :pages, foreign_key: "author_id", dependent: :destroy, inverse_of: :author
  has_many :tokens, class_name: "UserToken", dependent: :destroy

  # Normalizations
  normalizes :subdomain, with: ->(s) { s.strip.downcase.encode("UTF-8", invalid: :replace, undef: :replace, replace: "") }

  # Validations
  validates :subdomain,
    uniqueness: true,
    format: {with: /\A[a-z0-9\-_]+\z/, message: "may only contain letters, numbers, hyphens and underscores"},
    length: {minimum: 3, maximum: 63},
    exclusion: {in: ::ReservedWords::RESERVED_WORDS},
    allow_blank: true
  validates :name, presence: true, length: {maximum: 255}, allow_blank: true
  validates :blog_title, length: {maximum: 255}, allow_blank: true
  validates :site_meta_description, length: {maximum: 255}, allow_blank: true
  validates :favicon_emoji, presence: true, format: {with: /\A(?:\p{Emoji_Presentation}|\p{Emoji}\uFE0F)\z/u, message: "must be a single emoji"}, allow_blank: true
end
