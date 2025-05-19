class User < ApplicationRecord
  extend FriendlyId
  friendly_id :subdomain

  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :posts, foreign_key: "author_id", dependent: :destroy
  has_many :tokens, class_name: "UserToken", dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  normalizes :subdomain, with: ->(s) { s.strip.downcase.encode("UTF-8", invalid: :replace, undef: :replace, replace: "").parameterize }

  validates :email_address, presence: true,
                           uniqueness: true,
                           format: { with: URI::MailTo::EMAIL_REGEXP, message: "must be a valid email address" }
  validates :subdomain, presence: true,
                       uniqueness: true,
                       format: { with: /\A[a-z0-9\-_]+\z/, message: "may only contain letters, numbers, hyphens and underscores" },
                       length: { minimum: 3, maximum: 63 },
                       exclusion: { in: friendly_id_config.reserved_words }
  validates :password, presence: true, length: { minimum: 6 }, allow_nil: true
  validates :name, presence: true, length: { maximum: 255 }, allow_blank: true
  validates :blog_title, length: { maximum: 255 }, allow_blank: true

  def to_key
    [ subdomain ]
  end
end
