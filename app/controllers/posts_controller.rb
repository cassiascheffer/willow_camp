class PostsController < ApplicationController
  allow_unauthenticated_access only: %i[index show]
  before_action :set_author, only: %i[index show]
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

  def set_author
    @author = User.find_by(subdomain: request.subdomain)
    if @author.nil?
      redirect_to root_url(subdomain: false)
    end
  end

  def set_post
    @post = @author.posts.published.find_by(slug: params[:slug])
    if @post.nil?
      redirect_to posts_path, alert: "Not found."
    end
  end
end
