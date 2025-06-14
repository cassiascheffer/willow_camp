class Dashboard::UsersController < Dashboard::BaseController
  before_action :set_user, only: [:edit, :update]

  def edit
  end

  def update
    params_to_update = user_params
    if params_to_update[:password].blank?
      params_to_update = params_to_update.except(:password, :password_confirmation)
    end
    if @user.update(params_to_update)
      flash[:notice] = "User profile successfully updated"
    else
      flash[:alert] = "There were errors updating your profile"
    end
    respond_to do |format|
      format.turbo_stream { render :update }
      format.html { redirect_to dashboard_settings_path }
    end
  end

  private

  def set_user
    if params[:id].present?
      @user = User.find(params[:id])
    end

    if @user != current_user
      head :not_found
    end
  end

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :subdomain, :custom_domain, :blog_title, :theme, :site_meta_description, :favicon_emoji)
  end
end
