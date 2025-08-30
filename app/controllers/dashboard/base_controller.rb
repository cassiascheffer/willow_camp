module Dashboard
  class BaseController < ApplicationController
    layout "dashboard"
    before_action :authenticate_user!
    before_action :set_author
    before_action :set_current_blog

    private

    def set_author
      @author = current_user
    end

    def set_current_blog
      if params[:blog_subdomain].present?
        @blog = current_user.blogs.find_by(subdomain: params[:blog_subdomain])
        redirect_to dashboard_path, alert: "Blog not found" unless @blog
      else
        @blog = current_user&.blogs&.find_by(primary: true) || current_user&.blogs&.first
      end
    end
  end
end
