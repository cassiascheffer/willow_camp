class PostsController < ApplicationController
  allow_unauthenticated_access only: %i[ index show ]
  before_action :set_author, only: %i[ index show ]
  before_action :set_post, only: %i[ show ]

  # GET /posts or /posts.json
  def index
    @posts = Post.where(author: @author, published: true).order(published_at: :desc, created_at: :desc)
  end

  # GET /posts/1 or /posts/1.json
  def show
  end

  private
    def set_author
      @author = User.find_by(subdomain: request.subdomain)
    end

    def set_post
      @post = Post.find_by(slug: params[:slug], author: @author, published: true)
      if @post.nil?
        redirect_to posts_path, alert: "Post not found."
      end
    end
end
