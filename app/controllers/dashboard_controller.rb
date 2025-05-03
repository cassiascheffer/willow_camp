class DashboardController < ApplicationController
  layout "dashboard"
  before_action :set_user

  def show
    @posts = Post.where(author: Current.user).order(published_at: :desc, created_at: :desc)
  end

  private
    def set_user
      @user = Current.user

      if @user.nil?
        redirect_to root_path, alert: "Please log in to access your dashboard."
      end
    end
end
