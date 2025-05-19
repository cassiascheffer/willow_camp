class Dashboard::TokensController < Dashboard::BaseController
  before_action :set_token, only: [ :destroy ]

  def create
    @token = Current.user.tokens.new(token_params)

    respond_to do |format|
      if @token.save
        @tokens = Current.user.tokens.order(created_at: :desc)
        format.turbo_stream do
          flash.now[:notice] = "Token created successfully"
        end
        format.html { redirect_to dashboard_settings_path, notice: "Token created successfully" }
      else
        format.turbo_stream { render turbo_stream: turbo_stream.replace("new_token", partial: "dashboard/settings/token_form", locals: { token: @token }) }
        format.html { redirect_to dashboard_settings_path, alert: "Failed to create token" }
      end
    end
  end

  def destroy
    respond_to do |format|
      if @token.destroy
        format.turbo_stream { flash.now[:notice] = "Token deleted successfully" }
      else
        format.turbo_stream { flash.now[:alert] = "Failed to delete token" }
      end
    end
  end

  private

  def set_token
    @token = Current.user.tokens.find_by(id: params[:id])
    head :not_found unless @token
  end

  def token_params
    params.require(:user_token).permit(:name, :expires_at)
  end
end
