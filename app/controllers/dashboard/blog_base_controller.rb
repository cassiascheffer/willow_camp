# ABOUTME: Base controller for blog-scoped dashboard resources
# ABOUTME: Provides blog context for nested resources like posts
class Dashboard::BlogBaseController < Dashboard::BaseController
  before_action :set_blog

  private

  def set_blog
    @blog = current_user.blogs.find_by!(subdomain: params[:blog_subdomain])
  rescue ActiveRecord::RecordNotFound
    redirect_to dashboard_path, alert: "Blog not found"
  end

  def current_blog
    @blog
  end
  helper_method :current_blog
end
