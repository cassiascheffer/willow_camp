# ABOUTME: Dashboard controller for managing user blogs
# ABOUTME: Handles creation and management of blogs for authenticated users
class Dashboard::BlogsController < Dashboard::BaseController
  before_action :set_blog, only: [:show, :update]

  def show
    @about_page = @blog.pages.find_or_create_by(title: "About", slug: "about")
  end

  def update
    if @blog.update(blog_params)
      redirect_to blog_dashboard_settings_path(@blog.subdomain), notice: "Blog settings updated successfully"
    else
      @about_page = @blog.pages.find_or_create_by(title: "About", slug: "about")
      render :show, status: :unprocessable_entity
    end
  end

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

  def set_blog
    @blog = current_user.blogs.find_by(subdomain: params[:blog_subdomain])
    redirect_to dashboard_path, alert: "Blog not found" unless @blog
  end

  def blog_params
    params.require(:blog).permit(:title, :subdomain, :custom_domain, :theme, :meta_description, :favicon_emoji, :post_footer_markdown, :no_index, :primary)
  end
end
