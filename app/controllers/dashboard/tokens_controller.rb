class Dashboard::TokensController < Dashboard::BaseController
  before_action :set_token, only: [:destroy]

  def create
    @token = current_user.tokens.new(token_params)
    @tokens = current_user.tokens.order(created_at: :desc)
    if @token.save
      respond_to do |format|
        format.turbo_stream do
          flash.now[:notice] = "Token created successfully"
        end
        format.html do
          flash[:notice] = "Token created successfully"
          redirect_to dashboard_user_settings_path
        end
      end
    else
      respond_to do |format|
        format.turbo_stream do
          flash.now[:alert] = "There were errors creating the token"
        end
        format.html do
          flash[:alert] = "There were errors creating the token"
          redirect_to dashboard_user_settings_path
        end
      end
    end
  end

  def destroy
    if @token.destroy
      flash[:notice] = "Token deleted successfully"
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to dashboard_user_settings_path }
      end
    else
      flash[:alert] = "Failed to delete token"
      redirect_to dashboard_user_settings_path
    end
  end

  private

  def set_token
    @token = current_user.tokens.find_by(id: params[:id])
    head :not_found unless @token
  end

  def token_params
    params.require(:user_token).permit(:name, :expires_at)
  end
end
