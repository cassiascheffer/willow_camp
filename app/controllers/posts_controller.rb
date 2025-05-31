class PostsController < ApplicationController
  allow_unauthenticated_access only: %i[index show]
  before_action :set_author, only: %i[index show]
  before_action :set_post, only: %i[show]

  def index
    @pagy, @posts = pagy(@author.posts.published.order(published_at: :desc).where(type: nil))
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
    @post = Post.published.find_by(slug: params[:slug], author_id: @author.id)
    if @post.nil?
      redirect_to posts_path, alert: "Post not found."
    end
  end
end
