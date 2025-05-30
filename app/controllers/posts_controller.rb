class PostsController < ApplicationController
  include Pagy::Backend
  allow_unauthenticated_access only: %i[index show]
  before_action :set_author, only: %i[index show]
  before_action :set_post, only: %i[show]

  def index
    # Use Pagy::Calendar for efficient year-based pagination
    @pagy, @posts_by_year = pagy_calendar(
      :year,
      @author.posts.published,
      year: {
        field: :published_at,
        format: "%Y",
        order: :desc
      },
      # Default sorting within a year
      page_param: :page,
      order: {published_at: :desc, created_at: :desc}
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
    @post = Post.published.find_by(slug: params[:slug], author: @author)
    if @post.nil?
      redirect_to posts_path, alert: "Post not found."
    end
  end
end
