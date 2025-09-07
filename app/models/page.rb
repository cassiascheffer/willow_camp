class Page < Post
  belongs_to :blog
  belongs_to :author, class_name: "User", optional: true

  before_validation :set_author_from_blog, if: -> { blog.present? && author.blank? }

  private

  def set_author_from_blog
    self.author = blog.user
  end
end
