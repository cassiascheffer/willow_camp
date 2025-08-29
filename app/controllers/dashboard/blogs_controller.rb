# ABOUTME: Dashboard controller for managing user blogs
# ABOUTME: Handles creation and management of blogs for authenticated users
class Dashboard::BlogsController < Dashboard::BaseController
  def create
    @blog = current_user.blogs.build(blog_params)

    if @blog.save
      # Redirect to the new blog's dashboard
      redirect_to blog_dashboard_path(@blog.subdomain), notice: "Blog created successfully!"
    else
      redirect_to dashboard_path, alert: "Error creating blog: #{@blog.errors.full_messages.join(", ")}"
    end
  end

  private

  def blog_params
    params.require(:blog).permit(:subdomain, :title, :primary)
  end
end
