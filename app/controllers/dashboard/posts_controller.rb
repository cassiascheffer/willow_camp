class Dashboard::PostsController < Dashboard::BaseController
  before_action :set_post, only: %i[edit update destroy]
  before_action :authorize_user!, only: %i[edit update destroy]

  def edit
    @tags = ActsAsTaggableOn::Tag.for_tenant(current_user.id).pluck(:name).uniq
  end

  def update
    # Handle social_share_image replacement to avoid Active Storage nil record error
    if post_params[:social_share_image].present? && @post.social_share_image.attached?
      @post.social_share_image.purge
    end

    if @post.update(post_params)
      respond_to do |format|
        format.html {
          redirect_to edit_dashboard_post_path(@post.id)
        }
        format.turbo_stream {
          render :update, status: :ok
        }
      end
    else
      respond_to do |format|
        format.html {
          flash.now[:alert] = "There were errors updating the post"
          render :edit, status: :unprocessable_entity
        }
        format.turbo_stream {
          flash.now[:alert] = "There were errors updating the post"
          render :update, status: :unprocessable_entity
        }
      end
    end
  end

  def destroy
    @post.destroy!
    redirect_to dashboard_path, notice: "Post deleted successfully"
  end

  private

  def set_post
    @post = current_user.posts.find(params[:id])
  end

  def authorize_user!
    redirect_to dashboard_path, alert: "Unauthorized" unless @post.author == current_user
  end

  def post_params
    permitted_params = [
      :title, :tag_list, :slug, :body_markdown, :published,
      :published_at, :meta_description, :featured
    ]

    # Only allow social_share_image parameter for users with the feature enabled
    permitted_params << :social_share_image if current_user.social_share_image_enabled?

    params.require(:post).permit(permitted_params)
  end
end
