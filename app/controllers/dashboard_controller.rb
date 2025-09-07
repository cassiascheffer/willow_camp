class DashboardController < Dashboard::BaseController
  layout "dashboard"

  def show
    @user = current_user

    if params[:blog_subdomain].present?
      @blog = @user.blogs.find_by(subdomain: params[:blog_subdomain])
      redirect_to dashboard_path, alert: "Blog not found" unless @blog
    else
      @blog = @user.blogs.find_by(primary: true) || @user.blogs.first
    end

    # Store the last viewed blog in session for breadcrumb navigation
    session[:last_viewed_blog_id] = @blog&.id if @blog

    # Handle new blog form display
    @new_blog = Blog.new(user: @user, primary: false) if params[:new_blog].present?

    if @blog
      @pagy, @posts = pagy(
        @blog.posts.not_page.order(published_at: :desc, created_at: :desc)
      )
    else
      @posts = []
    end
  end
end
