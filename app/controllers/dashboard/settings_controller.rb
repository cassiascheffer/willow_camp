module Dashboard
  class SettingsController < Dashboard::BaseController
    def show
      @user = current_user

      if params[:blog_subdomain].present?
        redirect_to dashboard_settings_path, alert: "Blog not found" unless @blog
        @about_page = @blog.pages.find_or_create_by(title: "About", slug: "about")
      else
        @tokens = @user.tokens.order(created_at: :desc)
        @about_page = nil # No user-level about page anymore
        @token = UserToken.new
      end
    end

    def update
      @user = current_user

      if params[:blog_subdomain].present?
        redirect_to dashboard_settings_path, alert: "Blog not found" unless @blog

        if @blog.update(blog_params)
          redirect_to blog_dashboard_settings_path(@blog.subdomain), notice: "Blog settings updated successfully"
        else
          @about_page = @blog.pages.find_or_create_by(title: "About", slug: "about")
          render :show, status: :unprocessable_entity
        end
      else
        redirect_to dashboard_settings_path, alert: "Blog not found"
      end
    end

    private

    def blog_params
      params.require(:blog).permit(:title, :subdomain, :custom_domain, :theme, :meta_description, :favicon_emoji, :post_footer_markdown)
    end
  end
end
