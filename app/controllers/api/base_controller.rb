class Api::BaseController < ApplicationController
  allow_unauthenticated_access
  before_action :authenticate_with_token!

  private
    def authenticate_with_token!
      token = request.headers["Authorization"].to_s.split(" ").last
      @current_user = UserToken.find_by(token: token)&.user
      unless @current_user
        render json: { error: "Unauthorized" }, status: :unauthorized
      end
    end
end
