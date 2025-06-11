class DashboardController < Dashboard::BaseController
  layout "dashboard"

  def show
    @user = current_user
    @pagy, @posts = pagy(
      @user.posts.not_page.order(published_at: :desc, created_at: :desc)
    )
  end
end
