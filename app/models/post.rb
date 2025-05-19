class Post < ApplicationRecord
  include Sluggable
  slug_unique_within_scope :author_id

  belongs_to :author, class_name: "User", foreign_key: "author_id"

  before_create :set_published_at
  before_save :set_html

  delegate :name, to: :author, prefix: true

  # Validations
  validates :title, presence: true, length: { maximum: 255 }
  validates :published, inclusion: { in: [ true, false ] }, allow_nil: true
  validates :body_markdown, length: { maximum: 100000 }, allow_blank: true

  private

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
