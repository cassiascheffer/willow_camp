class Dashboard::UsersController < ApplicationController
  before_action :set_user, only: [ :edit, :update ]
  def edit
  end

  def update
    if @user.update!(user_params)
      redirect_to dashboard_path, notice: "Your profile has been updated."
    else
      format.html { render :edit, status: :unprocessable_entity, notice: "There was a problem updating your profile." }
      format.json { render json: @user.errors, status: :unprocessable_entity }
    end
  end

  private
    def set_user
      @user = Current.user
    end

    def user_params
      params.require(:user).permit(:name, :email_address, :password, :password_confirmation, :subdomain, :blog_title, :theme)
    end
end
