class Dashboard::SettingsController < ApplicationController
  before_action :set_user

  def show
    @tokens = @user.tokens
    @token = UserToken.new
  end

  private

  def set_user
    @user = Current.user

    if @user.nil?
      redirect_to root_path, alert: "Please log in to access your dashboard."
    end
  end
end
