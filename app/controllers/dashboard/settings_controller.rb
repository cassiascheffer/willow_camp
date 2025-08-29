module Dashboard
  class SettingsController < Dashboard::BaseController
    def show
      @user = current_user

      if params[:blog_subdomain].present?
        @blog = @user.blogs.find_by(subdomain: params[:blog_subdomain])
        redirect_to dashboard_settings_path, alert: "Blog not found" unless @blog
      end

      @tokens = @user.tokens.order(created_at: :desc)
      @about_page = @user.pages.find_or_create_by(title: "About", slug: "about")
      @token = UserToken.new
    end
  end
end
