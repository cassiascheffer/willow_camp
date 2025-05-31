class PostsController < ApplicationController
  allow_unauthenticated_access only: %i[index show]
  before_action :set_author, only: %i[index show]
  before_action :set_post, only: %i[show]

  def index
    @pagy, @posts = pagy(@author.posts.published.order(published_at: :desc))
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

  def pagy_calendar_period(collection)
    starting = collection.minimum(:created_at)
    ending = collection.maximum(:created_at)
    [starting.in_time_zone, ending.in_time_zone]
  end

  def pagy_calendar_filter(collection, from, to)
    collection.where(created_at: from...to)
  end

  def pagy_calendar_counts(collection, unit, from, to)
    collection.group_by_period(unit, :created_at, range: from...to).count.values
  end
end
