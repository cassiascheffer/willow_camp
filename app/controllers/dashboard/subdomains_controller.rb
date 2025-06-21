class Dashboard::SubdomainsController < Dashboard::BaseController
  def update
    @user = current_user

    if @user.update(subdomain_params)
      redirect_to new_dashboard_post_path, notice: "Subdomain saved! Now create your first post."
    else
      redirect_to dashboard_path, alert: "Invalid subdomain. #{@user.errors.full_messages.join(", ")}"
    end
  end

  private

  def subdomain_params
    params.require(:user).permit(:subdomain)
  end
end
