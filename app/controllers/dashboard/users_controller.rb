class Dashboard::UsersController < ApplicationController
  before_action :set_user, only: [ :edit, :update ]
  def edit
  end

  def update
    respond_to do |format|
      if @user.update(user_params)
        format.turbo_stream { flash.now[:notice] = "Your profile has been updated." }
        format.html { redirect_to dashboard_settings_path, notice: "Your profile has been updated." }
      else
        format.turbo_stream { render turbo_stream: turbo_stream.replace(@user, partial: "dashboard/settings/form", locals: { user: @user }) }
        format.html { render "dashboard/settings/show", status: :unprocessable_entity }
      end
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
