class Dashboard::PostsController < Dashboard::BaseController
  before_action :set_post, only: %i[edit update destroy]
  before_action :authorize_user!, only: %i[edit update destroy]

  def new
    @post = Post.new
  end

  def create
    @post = @user.posts.new(post_params)

    if @post.save
      flash[:notice] = "Created!"
      redirect_to dashboard_path
    else
      flash.now[:alert] = "Oops! There were errors."
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    respond_to do |format|
      if @post.update(post_params)
        format.turbo_stream do
          flash.now[:form_status] = {type: "success", message: "Updated"}
          render turbo_stream: [
            turbo_stream.replace("edit_post_form", partial: "dashboard/posts/edit_form", locals: {post: @post})
          ]
        end
        format.html do
          flash[:form_status] = {type: "success", message: "Updated"}
          redirect_to dashboard_path
        end
      else
        format.turbo_stream do
          flash.now[:form_status] = {type: "error", message: "There were errors"}
          render turbo_stream: [
            turbo_stream.replace("edit_post_form", partial: "dashboard/posts/edit_form", locals: {post: @post})
          ]
        end
        format.html do
          flash.now[:form_status] = {type: "error", message: "There were errors"}
          render :edit, status: :unprocessable_entity
        end
      end
    end
  end

  def destroy
    @post.destroy
    redirect_to dashboard_path, notice: "Post was successfully destroyed"
  end

  private

  def set_post
    @post = @user.posts.find_by(slug: params[:slug])
  end

  def authorize_user!
    unless @post.author == @user
      redirect_to dashboard_path, alert: "You are not authorized to perform this action."
    end
  end

  def post_params
    params.require(:post).permit(
      :title,
      :tag_list,
      :slug,
      :body_markdown,
      :published,
      :published_at,
      :updated_at,
      :meta_description
    )
  end
end
