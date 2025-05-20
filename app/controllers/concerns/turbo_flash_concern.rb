module TurboFlashConcern
  extend ActiveSupport::Concern

  included do
    # Override the redirect_to method to handle Turbo Stream requests
    def redirect_to(options = {}, response_options = {})
      if turbo_stream_request? && (alert = response_options.delete(:alert) || flash[:alert])
        respond_to do |format|
          format.turbo_stream do
            flash.now[:alert] = alert
            render turbo_stream: turbo_stream.prepend("flash-messages", partial: "shared/flash", locals: {type: "alert", message: alert})
          end
          format.html { super }
        end
      elsif turbo_stream_request? && (notice = response_options.delete(:notice) || flash[:notice])
        respond_to do |format|
          format.turbo_stream do
            flash.now[:notice] = notice
            render turbo_stream: turbo_stream.prepend("flash-messages", partial: "shared/flash", locals: {type: "notice", message: notice})
          end
          format.html { super }
        end
      else
        super
      end
    end

    # Helper method to check if the current request is a Turbo Stream request
    def turbo_stream_request?
      request.format.turbo_stream? || request.headers["Accept"]&.include?("text/vnd.turbo-stream.html")
    end
  end

  # Add a helper method to send flash messages via Turbo Stream
  def respond_with_turbo_flash(type, message)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.prepend("flash-messages", partial: "shared/flash", locals: {type: type, message: message})
      end
      format.html do
        flash[type] = message
        redirect_back(fallback_location: dashboard_path)
      end
    end
  end
end
