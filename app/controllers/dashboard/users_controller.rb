class Dashboard::UsersController < Dashboard::BaseController
  before_action :set_user, only: [:edit, :update]

  def edit
  end

  def update
    if @user.update(user_params)
      flash[:notice] = "User profile successfully updated"
      redirect_to dashboard_settings_path
    else
      flash[:alert] = "There were errors updating your profile"
      redirect_to dashboard_settings_path
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
