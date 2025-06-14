class User < ApplicationRecord
  # Devise modules
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :trackable, :validatable

  # Associations
  has_many :posts, foreign_key: "author_id", dependent: :destroy, inverse_of: :author
  has_many :pages, foreign_key: "author_id", dependent: :destroy, inverse_of: :author
  has_many :tokens, class_name: "UserToken", dependent: :destroy

  # Normalizations
  normalizes :subdomain, with: ->(s) { s.strip.downcase.encode("UTF-8", invalid: :replace, undef: :replace, replace: "") }
  normalizes :custom_domain, with: ->(s) { s.strip.downcase.encode("UTF-8", invalid: :replace, undef: :replace, replace: "") }

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
  validates :custom_domain,
    uniqueness: true,
    format: {with: /\A[a-z0-9\-]+(\.[a-z0-9\-]+)*\.[a-z]{2,}\z/, message: "must be a valid domain name"},
    allow_blank: true

  # Domain helper methods
  def domain
    return custom_domain if custom_domain.present?
    return "#{subdomain}.willow.camp" if subdomain.present?
    nil
  end

  def uses_custom_domain?
    custom_domain.present?
  end

  def should_redirect_to_custom_domain?(current_host)
    return false unless uses_custom_domain?
    current_host != custom_domain
  end

  def self.find_by_domain(domain)
    return nil if domain.blank?

    # Normalize domain (remove port, convert to lowercase)
    normalized_domain = domain.split(":").first.downcase

    # First try to find by custom domain
    user = find_by(custom_domain: normalized_domain)
    return user if user.present?

    # Then try subdomain if it's a willow.camp domain
    if normalized_domain.ends_with?(".willow.camp")
      subdomain = normalized_domain.sub(".willow.camp", "")
      find_by(subdomain: subdomain) if subdomain.present?
    end
  end
end
