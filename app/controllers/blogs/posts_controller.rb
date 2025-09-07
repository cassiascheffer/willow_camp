class Blogs::PostsController < Blogs::BaseController
  before_action :set_post, only: %i[show]

  def index
    @featured_posts = @blog.posts
      .published
      .not_page
      .where(featured: true)
      .order(published_at: :desc)
      .limit(3)

    @pagy, @posts = pagy(
      @blog.posts
        .published
        .not_page
        .order(published_at: :desc)
    )
  end

  def show
    if @post.nil?
      respond_to do |format|
        format.html { render "not_found", status: :not_found }
        format.any { head :not_found }
      end
    end
  end

  private

  def set_post
    @post = @blog.posts.published.find_by(slug: params[:slug])
  end
end
