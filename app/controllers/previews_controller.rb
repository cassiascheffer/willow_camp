class PreviewsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_post
  before_action :authorize_preview

  layout "blog"

  def show
    @blog = @post.blog
    @author = @post.author
    render "blogs/posts/show"
  end

  private

  def set_post
    @post = Post.find(params[:id])
  end

  def authorize_preview
    redirect_to root_path unless @post.author == current_user
  end
end
