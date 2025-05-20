class Post < ApplicationRecord
  # Utilities
  extend FriendlyId
  friendly_id :title, use: [:sequentially_slugged, :scoped, :history], scope: :author
  acts_as_taggable_on :tags
  acts_as_taggable_tenant :author_id

  # Associations
  belongs_to :author, class_name: "User", foreign_key: "author_id"

  # Callbacks
  before_create :set_published_at
  before_save :set_html

  # Delegations
  delegate :name, to: :author, prefix: true

  # Validations
  validates :title, presence: true, length: {maximum: 255}
  validates :published, inclusion: {in: [true, false]}, allow_nil: true
  validates :body_markdown, length: {maximum: 100000}, allow_blank: true
  validates :published_at, presence: true, if: :published
  validates :meta_description, length: {maximum: 160}

  # Determines when friendly_id should generate a new slug
  def should_generate_new_friendly_id?
    title_changed? || super
  end

  def to_key
    [slug]
  end

  private

  def set_published_at
    if published && published_at.blank?
      self.published_at = DateTime.now
    end
  end

  def set_html
    if body_markdown.present?
      self.body_html = Commonmarker.parse(body_markdown, options: {
        extension: {footnotes: true},
        parse: {smart: true}
      }).to_html
    end
  end
end
