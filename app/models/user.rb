class User < ApplicationRecord
  # Devise modules
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :trackable, :validatable

  # Associations
  has_many :posts, foreign_key: "author_id", dependent: :destroy, inverse_of: :author
  has_many :pages, foreign_key: "author_id", dependent: :destroy, inverse_of: :author
  has_many :tokens, class_name: "UserToken", dependent: :destroy

  # Normalizations
  normalizes :subdomain, with: ->(s) { s.strip.downcase }
  normalizes :custom_domain, with: ->(s) { s.strip.downcase }

  # Validations
  validates :subdomain,
    uniqueness: true,
    format: {with: /\A[a-z0-9]+\z/, message: "may only contain letters and numbers"},
    length: {minimum: 3, maximum: 63},
    exclusion: {in: ::ReservedWords::RESERVED_WORDS},
    allow_blank: true
  validates :name, presence: true, length: {maximum: 255}, allow_blank: true
  validates :blog_title, length: {maximum: 255}, allow_blank: true
  validates :site_meta_description, length: {maximum: 255}, allow_blank: true
  validates :favicon_emoji,
    presence: true,
    format: {
      with: /\A(?:\p{Emoji_Presentation}|\p{Emoji}\uFE0F)\z/u,
      message: "must be a single emoji"
    },
    allow_blank: true
  validates :custom_domain,
    uniqueness: true,
    allow_blank: true
  validate :custom_domain_format

  # Scopes
  scope :by_domain, ->(domain) do
    return none if domain.blank?

    normalized_domain = domain.split(":").first.downcase

    if normalized_domain.ends_with?(".willow.camp")
      subdomain = normalized_domain.sub(".willow.camp", "")
      where(subdomain: subdomain) if subdomain.present?
    else
      where(custom_domain: normalized_domain)
    end
  end

  # Domain helper methods
  def domain
    return custom_domain if custom_domain.present?
    return "#{subdomain}.willow.camp" if subdomain.present?
    nil
  end

  def uses_custom_domain?
    custom_domain.present?
  end

  # TODO: not a model concern
  def should_redirect_to_custom_domain?(current_host)
    return false unless uses_custom_domain?
    current_host != custom_domain
  end

  private

  def custom_domain_format
    return if custom_domain.blank?

    domain_to_check = custom_domain.to_s.downcase.strip.chomp(".")
    double_dots = domain_to_check.include?("..")
    control_chars = domain_to_check.match?(/[[:cntrl:]]/)
    if double_dots || control_chars || !PublicSuffix.valid?(domain_to_check)
      errors.add(:custom_domain, "must be a valid domain name")
    end
  end
end
