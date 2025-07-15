class Blog::PostsController < Blog::BaseController
  before_action :set_post, only: %i[show]

  def index
    @pagy, @posts = pagy(
      @author.posts
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
    @post = @author.posts.published.find_by(slug: params[:slug])
  end
end
