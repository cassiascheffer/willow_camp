class Post < ApplicationRecord
  belongs_to :author, class_name: "User", foreign_key: "author_id"
  before_save :set_slug
  before_create :set_published_at

  def to_key
    [ self.slug ]
  end

  private
    def set_slug
      if self.slug.blank?
        return self.slug = "#{self.title.parameterize}-#{SecureRandom.hex(4)}"
      end
      if Post.where(slug: self.slug).where.not(id: self.id).exists?
        self.slug = "#{self.slug}-#{SecureRandom.hex(4)}"
      end
    end

    def set_published_at
      if self.published && self.published_at.blank?
        self.published_at = DateTime.now
      end
    end
end
