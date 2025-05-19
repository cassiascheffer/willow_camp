class Post < ApplicationRecord
  belongs_to :author, class_name: "User", foreign_key: "author_id"

  before_validation :set_slug, if: ->(post) { post.slug.blank? || post.title_changed? }
  before_create :set_published_at
  before_save :set_html

  delegate :name, to: :author, prefix: true

  # Validations
  validates :title, presence: true, length: { maximum: 255 }
  validates :slug, presence: true, uniqueness: true
  validates :published, inclusion: { in: [ true, false ] }, allow_nil: true
  validates :body_markdown, length: { maximum: 100000 }, allow_blank: true

  def to_key
    [ self.slug ]
  end

  # Define to_param for RESTful URLs based on slug
  def to_param
    slug
  end

  private
    def set_slug
      if self.slug.blank?
        # Use just the parameterized title as the slug
        parameterized_slug = self.title.parameterize

        # If this slug already exists, add a random hex
        if Post.where(slug: parameterized_slug).where.not(id: self.id).exists?
          self.slug = "#{parameterized_slug}-#{SecureRandom.hex(4)}"
        else
          self.slug = parameterized_slug
        end
      elsif Post.where(slug: self.slug).where.not(id: self.id).exists?
        self.slug = "#{self.slug}-#{SecureRandom.hex(4)}"
      end
    end

    def set_published_at
      if self.published && self.published_at.blank?
        self.published_at = DateTime.now
      end
    end

    def set_html
      if self.body_markdown.present?
        self.body_html = Commonmarker.parse(self.body_markdown, options: {
          extension: { footnotes: true },
          parse: { smart: true }
        }).to_html
      end
    end
end
