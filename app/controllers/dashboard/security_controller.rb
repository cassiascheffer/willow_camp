# ABOUTME: Handles security settings like password changes and API token management
# ABOUTME: Provides a dedicated page for security-related user settings

module Dashboard
  class SecurityController < Dashboard::BaseController
    layout 'security'
    
    def show
      @user = current_user
      @tokens = @user.tokens.order(created_at: :desc)
      @token = UserToken.new
      
      # Get the last viewed blog for breadcrumb navigation
      if session[:last_viewed_blog_id]
        @last_viewed_blog = @user.blogs.find_by(id: session[:last_viewed_blog_id])
      end
      @last_viewed_blog ||= @user.blogs.find_by(primary: true) || @user.blogs.first
    end
  end
end