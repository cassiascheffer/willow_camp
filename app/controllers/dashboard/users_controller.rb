class Dashboard::UsersController < Dashboard::BaseController
  before_action :set_user, only: [ :edit, :update ]

  def edit
  end

  def update
    respond_to do |format|
      if @user.update(user_params)
        format.turbo_stream do
          # Set flash for form status instead of global flash
          flash.now[:form_status] = { type: "success", message: "Updated" }
          render turbo_stream: turbo_stream.replace(@user, partial: "dashboard/settings/user_form", locals: { user: @user })
        end
        format.html do
          flash[:form_status] = { type: "success", message: "Updated" }
          redirect_to dashboard_settings_path
        end
      else
        format.turbo_stream do
          flash.now[:form_status] = { type: "error", message: "There were errors" }
          render turbo_stream: turbo_stream.replace(@user, partial: "dashboard/settings/user_form", locals: { user: @user })
        end
        format.html do
          flash[:form_status] = { type: "error", message: "There were errors" }
          redirect_to dashboard_settings_path
        end
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
