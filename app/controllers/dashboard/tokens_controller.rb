class Dashboard::TokensController < Dashboard::BaseController
  before_action :set_token, only: [ :destroy ]

  def create
    @token = Current.user.tokens.new(token_params)

    respond_to do |format|
      if @token.save
        @tokens = Current.user.tokens.order(created_at: :desc)
        format.turbo_stream do
          flash.now[:form_status] = { type: "success", message: "Created" }
          # Create a fresh token instance to clear the form
          @new_token = UserToken.new
          render turbo_stream: [
            turbo_stream.replace("tokens", partial: "dashboard/settings/token_list", locals: { tokens: @tokens }),
            turbo_stream.replace("new_token", partial: "dashboard/settings/token_form", locals: { token: @new_token }),
            turbo_stream.append_all("body", partial: "shared/form_reset_trigger")
          ]
        end
        format.html do
          flash[:form_status] = { type: "success", message: "Created" }
          redirect_to dashboard_settings_path
        end
      else
        format.turbo_stream do
          flash.now[:form_status] = { type: "error", message: "There were errors" }
          render turbo_stream: turbo_stream.replace("new_token", partial: "dashboard/settings/token_form", locals: { token: @token })
        end
        format.html do
          flash[:form_status] = { type: "error", message: "There were errors" }
          redirect_to dashboard_settings_path
        end
      end
    end
  end

  def destroy
    respond_to do |format|
      if @token.destroy
        @tokens = Current.user.tokens.order(created_at: :desc)
        format.turbo_stream do
          flash.now[:form_status] = { type: "success", message: "Deleted" }
          render turbo_stream: [
            turbo_stream.replace("tokens", partial: "dashboard/settings/token_list", locals: { tokens: @tokens }),
            turbo_stream.replace("new_token", partial: "dashboard/settings/token_form", locals: { token: UserToken.new }),
            turbo_stream.append_all("body", partial: "shared/form_reset_trigger")
          ]
        end
        format.html do
          flash[:form_status] = { type: "success", message: "Deleted" }
          redirect_to dashboard_settings_path
        end
      else
        format.turbo_stream do
          flash.now[:form_status] = { type: "error", message: "Failed to delete" }
          render turbo_stream: turbo_stream.replace("new_token", partial: "dashboard/settings/token_form", locals: { token: UserToken.new })
        end
        format.html do
          flash[:form_status] = { type: "error", message: "Failed to delete" }
          redirect_to dashboard_settings_path
        end
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
