class Dashboard::UsersController < Dashboard::BaseController
  before_action :set_user, only: [:show, :edit, :update]

  def show
    @tokens = @user.tokens.order(created_at: :desc)
    @token = UserToken.new
  end

  def edit
  end

  def update
    if params[:id].present?
      # Handle user profile updates (from edit action)
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
        format.html { redirect_to dashboard_user_settings_path }
      end
    elsif @user.update(user_params)
      # Handle user settings updates (from show action)
      redirect_to dashboard_user_settings_path, notice: "User settings updated successfully"
    else
      @tokens = @user.tokens.order(created_at: :desc)
      @token = UserToken.new
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = if params[:id].present?
      User.find(params[:id])
    else
      current_user
    end

    if @user != current_user
      head :not_found
    end
  end

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end
end
