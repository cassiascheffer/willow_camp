class PostsController < ApplicationController
  include Pagy::Backend
  allow_unauthenticated_access only: %i[ index show ]
  before_action :set_author, only: %i[ index show ]
  before_action :set_post, only: %i[ show ]

  def index
    @pagy, @posts = pagy(
      @author.posts.where(published: true).order(published_at: :desc, created_at: :desc)
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
      @post = Post.find_by(slug: params[:slug], author: @author, published: true)
      if @post.nil?
        redirect_to posts_path, alert: "Post not found."
      end
    end
end
