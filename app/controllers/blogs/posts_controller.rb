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
    else
      expires_in 5.minutes, public: true
      # stale? returns true if we need to render, false if returning 304
      # Only eager load rich text content if we're actually going to render
      if stale?(@post, public: true)
        @post = @blog.posts.published.includes(:rich_text_body_content).find(@post.id)
      end
    end
  end

  private

  def set_post
    # Load minimal post data for conditional GET check
    @post = @blog.posts.published.find_by(slug: params[:slug])
  end
end
