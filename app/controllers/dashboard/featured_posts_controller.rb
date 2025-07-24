class Dashboard::FeaturedPostsController < Dashboard::BaseController
  before_action :set_post

  def update
    if @post.update(featured_params)
      head :no_content
    else
      respond_to do |format|
        format.turbo_stream { 
          flash.now[:alert] = "Failed to update featured status"
          render turbo_stream: turbo_stream.update("flash-messages", render_to_string(partial: "shared/flash_messages"))
        }
        format.html { redirect_to dashboard_path, alert: "Failed to update featured status" }
      end
    end
  end

  private

  def set_post
    @post = current_user.posts.find(params[:id])
  end

  def featured_params
    params.permit(:featured)
  end
end