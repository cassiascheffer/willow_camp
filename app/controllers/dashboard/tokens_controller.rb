class Dashboard::TokensController < Dashboard::BaseController
  before_action :set_token, only: [:destroy]

  def create
    @token = Current.user.tokens.new(token_params)
    if @token.save
      flash[:notice] = "Token created successfully"
    else
      flash[:alert] = "There were errors creating the token"
    end
    redirect_to dashboard_settings_path
  end

  def destroy
    if @token.destroy
      flash[:notice] = "Token deleted successfully"
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to dashboard_settings_path }
      end
    else
      flash[:alert] = "Failed to delete token"
      redirect_to dashboard_settings_path
    end
  end

  private

  def set_token
    @token = @user.tokens.find_by(id: params[:id])
    head :not_found unless @token
  end

  def token_params
    params.require(:user_token).permit(:name, :expires_at)
  end
end
