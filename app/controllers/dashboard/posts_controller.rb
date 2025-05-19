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
          flash.now[:form_status] = { type: "success", message: "Updated" }
          render turbo_stream: [
            turbo_stream.replace("new_post_form", partial: "dashboard/posts/form", locals: { post: Post.new })
          ]
        end
        format.html do
          flash[:form_status] = { type: "success", message: "Updated" }
          redirect_to dashboard_path
        end
      else
        format.turbo_stream do
          flash.now[:form_status] = { type: "error", message: "There were errors" }
          render turbo_stream: [
            turbo_stream.replace("new_post_form", partial: "dashboard/posts/form", locals: { post: @post })
          ]
        end
        format.html do
          flash.now[:form_status] = { type: "error", message: "There were errors" }
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
          flash.now[:form_status] = { type: "success", message: "Updated" }
          render turbo_stream: [
            turbo_stream.replace("edit_post_form", partial: "dashboard/posts/form", locals: { post: @post })
          ]
        end
        format.html do
          flash[:form_status] = { type: "success", message: "Updated" }
          redirect_to dashboard_path
        end
      else
        format.turbo_stream do
          flash.now[:form_status] = { type: "error", message: "There were errors" }
          render turbo_stream: [
            turbo_stream.replace("edit_post_form", partial: "dashboard/posts/form", locals: { post: @post })
          ]
        end
        format.html do
          flash.now[:form_status] = { type: "error", message: "There were errors" }
          render :edit, status: :unprocessable_entity
        end
      end
    end
  end

  def destroy
    @post.destroy

    respond_to do |format|
      format.turbo_stream do
        # For destroy, we still want to show some sort of notification
        # Since there's no form to update after deletion, we'll keep using the flash-messages
        # But we'll modify it to be less intrusive in a future update if needed
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
