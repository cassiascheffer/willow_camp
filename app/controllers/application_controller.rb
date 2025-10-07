class ApplicationController < ActionController::Base
  include Pagy::Backend

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action do
    Honeybadger.context({
      user_id: current_user&.id,
      current_host: request.host,
      remote_ip: request.remote_ip,
      user_agent: request.user_agent
    })
  end

  protected

  def redirect_if_authenticated
    if user_signed_in? && params[:controller] == "devise/sessions" && params[:action] == "new"
      redirect_to dashboard_path
    end
  end
end
