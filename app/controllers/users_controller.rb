class UsersController < ApplicationController
  allow_unauthenticated_access only: [ :show, :create ]
  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      start_new_session_for(@user)
      redirect_to after_authentication_url, notice: "Welcome to the site!"
    else
      render :new
    end
  end

  private
    def user_params
      params.require(:user).permit(:name, :email_address, :password, :password_confirmation, :subdomain, :name)
    end
end
