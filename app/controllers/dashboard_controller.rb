class DashboardController < ApplicationController
  layout "dashboard"
  def show
    @posts = Post.where(author: Current.user).order(published_at: :desc, created_at: :desc)
  end
end
