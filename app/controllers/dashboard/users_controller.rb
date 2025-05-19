class Dashboard::UsersController < ApplicationController
  before_action :set_user, only: [ :edit, :update ]
  def edit
  end

  def update
    if @user.update!(user_params)
      redirect_to edit_dashboard_user_path, notice: "Your profile has been updated."
    else
      render :edit
    end
  end

  private
    def set_user
      @user = Current.user
    end

    def user_params
      params.require(:user).permit(:name, :email_address, :password, :password_confirmation, :subdomain)
    end
end
