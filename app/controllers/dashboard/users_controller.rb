class Dashboard::UsersController < Dashboard::BaseController
  before_action :set_user, only: [ :edit, :update ]

  def edit
  end

  def update
    respond_to do |format|
      if @user.update(user_params)
        format.turbo_stream do
          flash.now[:notice] = "Your profile has been updated."
          render turbo_stream: turbo_stream.replace(@user, partial: "dashboard/settings/user_form", locals: { user: @user })
        end
      else
        format.turbo_stream do
          flash.now[:alert] = "There was a problem updating your profile."
          render turbo_stream: turbo_stream.replace(@user, partial: "dashboard/settings/user_form", locals: { user: @user })
        end
      end
    end
  end

  private
    def set_user
      if params[:id].present?
        @user = User.find_by(id: params[:id])
      end

      if @user != Current.user
        head :not_found
      end
    end

    def user_params
      params.require(:user).permit(:name, :email_address, :password, :password_confirmation, :subdomain, :blog_title, :theme)
    end
end
