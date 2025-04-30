class Dashboard::PostsController < ApplicationController
  layout "dashboard"
  before_action :set_author
  before_action :set_post, only: %i[ edit update destroy ]
  before_action :authorize_user!, only: %i[ edit update destroy ]

  def new
    @post = Post.new
  end

  def create
    @post = Post.new(post_params)
    @post.author = @author
    if @post.save
      redirect_to dashboard_path, notice: "Post was successfully created."
    else
      render :new, alert: "There was an error creating the post."
    end
  end

  def edit
  end

  def update
    if @post.update(post_params)
      redirect_to dashboard_path, notice: "Post was successfully updated."
    else
      render :edit
    end
  end

  def destroy
    @post.destroy
    redirect_to dashboard_path, notice: "Post was successfully destroyed."
  end

  private
    def set_author
      @author = Current.user
    end

    def set_post
      @post = Post.find(params[:id])
    end

    def authorize_user!
      unless @post.author == @author
        redirect_to dashboard_path, alert: "You are not authorized to perform this action."
      end
    end

    def post_params
      params.require(:post).permit(:title, :body_markdown, :slug, :published, :published_at, :updated_at)
    end
end
