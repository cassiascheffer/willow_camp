class Dashboard::PostsController < Dashboard::BaseController
  before_action :set_post, only: %i[ edit update destroy ]
  before_action :authorize_user!, only: %i[ edit update destroy ]

  def new
    @post = Post.new
  end

  def create
    @post = Post.new(post_params)
    @post.author = @user
    if @post.save
      redirect_to dashboard_path, notice: "Post was successfully created."
    else
      flash.now[:alert] = "There was an error creating the post."
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @post.update(post_params)
      redirect_to dashboard_path, notice: "Post was successfully updated."
    else
      flash.now[:alert] = "There was an error updating the post."
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @post.destroy
    redirect_to dashboard_path, notice: "Post was successfully destroyed."
  end

  private


    def set_post
      @post = Post.find_by(slug: params[:slug])
    end

    def authorize_user!
      unless @post.author == @user
        redirect_to dashboard_path, alert: "You are not authorized to perform this action."
      end
    end

    def post_params
      params.require(:post).permit(:title, :body_markdown, :slug, :published, :published_at, :updated_at)
    end
end
