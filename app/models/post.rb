# Single Table Inheritance: Post and Page share the same table, differentiated by the 'type' column.
class Post < ApplicationRecord
  # Concerns
  include ProcessableImage

  # Utilities
  extend FriendlyId
  friendly_id :title, use: [:sequentially_slugged, :scoped, :history], scope: :blog
  acts_as_taggable_on :tags
  acts_as_taggable_tenant :blog_id

  # Associations
  belongs_to :author, class_name: "User"
  belongs_to :blog, optional: true
  has_many_attached :content_images

  # Callbacks
  before_validation :set_published_at
  before_save :set_html

  # Delegations
  delegate :name, to: :author, prefix: true

  # Validations
  validates :title, presence: true, length: {maximum: 255}
  validates :published, inclusion: {in: [true, false]}, allow_nil: true
  validates :body_markdown, length: {maximum: 100000}, allow_blank: true
  validates :published_at, presence: true, if: :published
  validates :meta_description, length: {maximum: 255}, allow_blank: true

  # Frontmatter
  attr_accessor :frontmatter

  # Scopes
  scope :published, -> { where(published: true) }
  scope :not_page, -> { where(type: nil) }

  # Class methods
  # Build a new Post from markdown content with frontmatter
  # @param markdown_content [String] Content of markdown file with frontmatter
  # @param author_or_blog [User, Blog] Author of the post or Blog it belongs to
  # @param author [User] Optional author when first param is a Blog
  # @return [Post] A new Post instance with attributes set from frontmatter
  def self.from_markdown(markdown_content, author_or_blog, author = nil)
    return nil unless markdown_content.present? && author_or_blog.present?

    # Maintain backwards compatibility
    if author_or_blog.is_a?(User)
      # Old signature: from_markdown(content, author)
      post = author_or_blog.posts.build
    else
      # New signature: from_markdown(content, blog, author)
      author ||= author_or_blog.user
      post = author_or_blog.posts.build(author: author)
    end
    service = UpdatePostFromMd.new(markdown_content, post)
    service.call
  end

  # Determines when friendly_id should generate a new slug
  def should_generate_new_friendly_id?
    title_changed? || super
  end

  def to_key
    [slug]
  end

  # Retrieves a specific frontmatter attribute
  def frontmatter_attribute(key)
    frontmatter&.dig(key.to_s)
  end

  def draft?
    !published
  end

  private

  def set_published_at
    if published && published_at.blank?
      self.published_at = DateTime.now
    end
  end

  def set_html
    self.body_html = PostMarkdown.new(body_markdown).to_html
    # Detect if markdown contains mermaid diagrams
    self.has_mermaid_diagrams = body_markdown&.include?("```mermaid") || false
  end
end
