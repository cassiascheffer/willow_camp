class Blog::TagsController < Blog::BaseController
  before_action :set_tag, only: [:show]

  def index
    @tags = ActsAsTaggableOn::Tag.for_tenant(@author.id)
      .joins(:taggings)
      .joins("INNER JOIN posts ON taggings.taggable_id = posts.id AND taggings.taggable_type = 'Post'")
      .where(posts: {author_id: @author.id, published: true})
      .group("tags.id, tags.name")
      .select("tags.*, COUNT(posts.id) as posts_count")
      .order("tags.name")
  end

  def show
    @pagy, @posts = pagy(
      Post.published.where(author: @author).tagged_with(@tag.name).order(created_at: :desc)
    )
  end

  private

  def set_tag
    @tag = ActsAsTaggableOn::Tag.for_tenant(@author.id).friendly.find(params[:tag])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_url
  end

  def set_author
    set_author_with_secure_redirect
  end
end
