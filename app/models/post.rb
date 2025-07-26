# Single Table Inheritance: Post and Page share the same table, differentiated by the 'type' column.
class Post < ApplicationRecord
  # Utilities
  extend FriendlyId
  friendly_id :title, use: [:sequentially_slugged, :scoped, :history], scope: :author
  acts_as_taggable_on :tags
  acts_as_taggable_tenant :author_id

  # Associations
  belongs_to :author, class_name: "User"
  has_one_attached :social_share_image

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
  # @param author [User] Author of the post
  # @return [Post] A new Post instance with attributes set from frontmatter
  def self.from_markdown(markdown_content, author)
    return nil unless markdown_content.present? && author.present?

    # Use the service to build the post
    # The service will handle parsing the frontmatter and creating the post
    service = BuildPostFromMd.new(markdown_content, author)
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
