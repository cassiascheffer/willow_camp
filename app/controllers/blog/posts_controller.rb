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
  end

  private

  def set_post
    @post = @author.posts.published.find_by(slug: params[:slug])
    if @post.nil?
      redirect_to posts_path, alert: "Not found.", allow_other_host: true
    end
  end
end
