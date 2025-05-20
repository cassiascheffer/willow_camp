class DashboardController < ApplicationController
  include Pagy::Backend

  layout "dashboard"
  before_action :set_user

  def show
    @pagy, @posts = pagy(Post.where(author: Current.user).order(published_at: :desc, created_at: :desc))
  end

  private
    def set_user
      @user = Current.user

      if @user.nil?
        redirect_to root_path, alert: "Please log in to access your dashboard."
      end
    end
end
