# ABOUTME: Blog model representing individual blogs in the multi-tenant system
# ABOUTME: Each blog belongs to a user and contains posts, pages, and configuration
require "unicode/emoji"

class Blog < ApplicationRecord
  # Associations
  belongs_to :user, counter_cache: :blogs_count
  has_many :posts, dependent: :destroy
  has_many :pages, dependent: :destroy
  has_rich_text :post_footer_content

  # Normalizations
  normalizes :subdomain, with: ->(s) { s.strip.downcase }
  normalizes :custom_domain, with: ->(s) { s.strip.downcase.presence }

  # Callbacks
  before_save :set_post_footer_html
  after_create_commit :ensure_about_page

  # Validations
  validates :subdomain,
    uniqueness: true,
    format: {with: /\A[a-z0-9]+\z/, message: "may only contain letters and numbers"},
    length: {minimum: 3, maximum: 63},
    exclusion: {in: ::ReservedWords::RESERVED_WORDS},
    allow_blank: true
  validates :title, length: {maximum: 255}, allow_blank: true
  validates :meta_description, length: {maximum: 255}, allow_blank: true
  validates :post_footer_markdown, length: {maximum: 10000}, allow_blank: true
  validates :favicon_emoji,
    presence: true,
    format: {
      with: /\A#{Unicode::Emoji::REGEX}\z/o,
      message: "must be a single emoji"
    },
    allow_blank: true
  validates :custom_domain,
    uniqueness: true,
    allow_blank: true
  validate :custom_domain_format
  validates :primary, inclusion: {in: [true, false]}
  validate :only_one_primary_per_user
  validate :user_blog_limit

  # Scopes
  scope :by_domain, ->(domain) do
    return none if domain.blank?

    normalized_domain = domain.split(":").first.downcase

    if normalized_domain.ends_with?(".willow.camp")
      subdomain = normalized_domain.sub(".willow.camp", "")
      where(subdomain: subdomain) if subdomain.present?
    elsif Rails.env.local? && normalized_domain.ends_with?(".localhost")
      subdomain = normalized_domain.sub(".localhost", "")
      where(subdomain: subdomain) if subdomain.present?
    else
      where(custom_domain: normalized_domain)
    end
  end

  # Tag helper methods
  def all_tags
    # Get all unique tags used on this blog's posts
    ActsAsTaggableOn::Tag.joins(:taggings)
      .where(taggings: {taggable_type: "Post", taggable_id: posts.pluck(:id)})
      .distinct
      .order(:name)
  end

  def tags_with_counts
    # Get tags with their usage counts on published posts
    ActsAsTaggableOn::Tag
      .select("tags.*, COUNT(DISTINCT taggings.taggable_id) as taggings_count")
      .joins(:taggings)
      .joins("INNER JOIN posts ON posts.id = taggings.taggable_id")
      .where(taggings: {taggable_type: "Post", taggable_id: posts.published.pluck(:id)})
      .group("tags.id")
      .order(Arel.sql("COUNT(DISTINCT taggings.taggable_id) DESC"))
  end

  def all_tags_with_counts
    # Get tags with their usage counts on all posts (published and unpublished)
    ActsAsTaggableOn::Tag
      .select("tags.*, COUNT(DISTINCT taggings.taggable_id) as taggings_count")
      .joins(:taggings)
      .joins("INNER JOIN posts ON posts.id = taggings.taggable_id")
      .where(taggings: {taggable_type: "Post", taggable_id: posts.pluck(:id)})
      .group("tags.id")
      .order(Arel.sql("COUNT(DISTINCT taggings.taggable_id) DESC"))
  end

  def all_tags_with_published_and_draft_counts
    # Get tags with separate counts for published and draft posts
    ActsAsTaggableOn::Tag
      .select(
        "tags.*,
         COUNT(DISTINCT CASE WHEN posts.published = true THEN taggings.taggable_id END) as published_count,
         COUNT(DISTINCT CASE WHEN posts.published = false OR posts.published IS NULL THEN taggings.taggable_id END) as draft_count,
         COUNT(DISTINCT taggings.taggable_id) as taggings_count"
      )
      .joins(:taggings)
      .joins("INNER JOIN posts ON posts.id = taggings.taggable_id")
      .where(taggings: {taggable_type: "Post", taggable_id: posts.pluck(:id)})
      .group("tags.id")
      .order(Arel.sql("COUNT(DISTINCT taggings.taggable_id) DESC"))
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

  # Backwards compatibility methods for post_footer_html
  def post_footer_html
    # If we have ActionText content, use it
    return post_footer_content.to_s if post_footer_content.present?
    # Otherwise fall back to the column value (for existing records)
    read_attribute(:post_footer_html)
  end

  def post_footer_html=(value)
    # When setting post_footer_html directly, update the ActionText content
    self.post_footer_content = value
    # Also store in the column for backwards compatibility during migration
    write_attribute(:post_footer_html, value)
  end

  private

  def set_post_footer_html
    html_content = if post_footer_markdown.present?
      PostMarkdown.new(post_footer_markdown).to_html
    end
    # Set both ActionText and column for backwards compatibility
    self.post_footer_content = html_content
    write_attribute(:post_footer_html, html_content)
  end

  def ensure_about_page
    pages.create!(title: "About", slug: "about")
  end

  def custom_domain_format
    return if custom_domain.blank?

    domain_to_check = custom_domain.to_s.downcase.strip.chomp(".")
    double_dots = domain_to_check.include?("..")
    control_chars = domain_to_check.match?(/[[:cntrl:]]/)
    if double_dots || control_chars || !PublicSuffix.valid?(domain_to_check)
      errors.add(:custom_domain, "must be a valid domain name")
    end
  end

  def only_one_primary_per_user
    return unless primary?

    existing_primary = user.blogs.where(primary: true).where.not(id: id)
    if existing_primary.exists?
      errors.add(:primary, "can only have one primary blog per user")
    end
  end

  def user_blog_limit
    return unless user

    if new_record? && user.blogs_count >= 2
      errors.add(:base, "User cannot have more than 2 blogs")
      nil
    end
  end
end
