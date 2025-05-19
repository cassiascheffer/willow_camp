class Dashboard::PostsController < Dashboard::BaseController
  before_action :set_post, only: %i[ edit update destroy ]
  before_action :authorize_user!, only: %i[ edit update destroy ]

  def new
    @post = Post.new
  end

  def create
    @post = Post.new(post_params)
    @post.author = @user

    respond_to do |format|
      if @post.save
        format.turbo_stream do
          flash.now[:notice] = "Post was successfully created."
          render turbo_stream: turbo_stream.prepend("flash-messages", partial: "shared/flash", locals: { type: "notice", message: "Post was successfully created." })
        end
        format.html { redirect_to dashboard_path, notice: "Post was successfully created." }
      else
        format.turbo_stream do
          flash.now[:alert] = "There was an error creating the post."
          render turbo_stream: [
            turbo_stream.replace("new_post_form", partial: "dashboard/posts/form", locals: { post: @post }),
            turbo_stream.prepend("flash-messages", partial: "shared/flash", locals: { type: "alert", message: "There was an error creating the post." })
          ]
        end
        format.html do
          flash.now[:alert] = "There was an error creating the post."
          render :new, status: :unprocessable_entity
        end
      end
    end
  end

  def edit
  end

  def update
    respond_to do |format|
      if @post.update(post_params)
        format.turbo_stream do
          flash.now[:notice] = "Post was successfully updated."
          render turbo_stream: turbo_stream.prepend("flash-messages", partial: "shared/flash", locals: { type: "notice", message: "Post was successfully updated." })
        end
        format.html { redirect_to dashboard_path, notice: "Post was successfully updated." }
      else
        format.turbo_stream do
          flash.now[:alert] = "There was an error updating the post."
          render turbo_stream: [
            turbo_stream.replace("edit_post_form", partial: "dashboard/posts/form", locals: { post: @post }),
            turbo_stream.prepend("flash-messages", partial: "shared/flash", locals: { type: "alert", message: "There was an error updating the post." })
          ]
        end
        format.html do
          flash.now[:alert] = "There was an error updating the post."
          render :edit, status: :unprocessable_entity
        end
      end
    end
  end

  def destroy
    @post.destroy

    respond_to do |format|
      format.turbo_stream do
        flash.now[:notice] = "Post was successfully destroyed."
        render turbo_stream: [
          turbo_stream.remove(dom_id(@post)),
          turbo_stream.prepend("flash-messages", partial: "shared/flash", locals: { type: "notice", message: "Post was successfully destroyed." })
        ]
      end
      format.html { redirect_to dashboard_path, notice: "Post was successfully destroyed." }
    end
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
