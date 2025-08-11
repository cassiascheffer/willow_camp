class Api::PostsController < Api::BaseController
  before_action :set_post, only: [:show, :update, :destroy]
  before_action :ensure_author, only: [:show, :update, :destroy]

  def index
    @posts = Post.where(author: @current_user).includes(:taggings)
    # Render with index.json.jbuilder
  end

  def show
    # Render with show.json.jbuilder
  end

  def create
    @post = @current_user.posts.build
    @post = UpdatePostFromMd.new(post_params[:markdown], @post).call

    if @post.save
      render :create, status: :created
    else
      render json: {errors: @post.errors.full_messages}, status: :unprocessable_content
    end
  end

  def update
    @post = UpdatePostFromMd.new(post_params[:markdown], @post).call
    if @post.save
      render :update
    else
      render json: {errors: @post.errors.full_messages}, status: :unprocessable_content
    end
  end

  def destroy
    @post.destroy
    head :no_content
  end

  private

  def set_post
    @post = @current_user.posts.find_by(slug: params[:slug])
    unless @post
      render json: {error: "Post not found"}, status: :not_found
    end
  end

  def ensure_author
    unless @post&.author_id == @current_user.id
      render json: {error: "You don't have permission to access this post"}, status: :forbidden
    end
  end

  def post_params
    params.require(:post).permit(:markdown)
  end
end
