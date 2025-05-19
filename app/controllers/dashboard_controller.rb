class DashboardController < ApplicationController
  def show
    @posts = Post.where(author: Current.user).order(published_at: :desc, created_at: :desc)
  end
end
