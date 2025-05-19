class PostsController < ApplicationController
  allow_unauthenticated_access only: %i[ index show ]
  before_action :set_author_for_reading, only: %i[ index show ]

  # GET /posts or /posts.json
  def index
    @posts = Post.where(author: @author)
  end

  # GET /posts/1 or /posts/1.json
  def show
  end
end
