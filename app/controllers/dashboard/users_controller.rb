class Dashboard::UsersController < Dashboard::BaseController
  before_action :set_user, only: [ :edit, :update ]

  def edit
  end

  def update
    respond_to do |format|
      if @user.update(user_params)
        format.turbo_stream do
          flash.now[:notice] = "Your profile has been updated."
          render turbo_stream: [
            turbo_stream.replace(@user, partial: "dashboard/settings/user_form", locals: { user: @user }),
            turbo_stream.prepend("flash-messages", partial: "shared/flash", locals: { type: "notice", message: "Your profile has been updated." })
          ]
        end
        format.html { redirect_to dashboard_settings_path, notice: "Your profile has been updated." }
      else
        format.turbo_stream do
          flash.now[:alert] = "There was a problem updating your profile."
          render turbo_stream: [
            turbo_stream.replace(@user, partial: "dashboard/settings/user_form", locals: { user: @user }),
            turbo_stream.prepend("flash-messages", partial: "shared/flash", locals: { type: "alert", message: "There was a problem updating your profile." })
          ]
        end
        format.html { redirect_to dashboard_settings_path, alert: "There was a problem updating your profile." }
      end
    end
  end

  private
    def set_user
      if params[:slug].present?
        @user = User.find(params[:slug])
      end

      if @user != Current.user
        head :not_found
      end
    end

    def user_params
      params.require(:user).permit(:name, :email_address, :password, :password_confirmation, :subdomain, :blog_title, :theme)
    end
end
