class Api::BaseController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :authenticate_with_token!

  private

  def authenticate_with_token!
    token = request.headers["Authorization"].to_s.split(" ").last
    @current_user = UserToken.active.find_by(token: token)&.user
    unless @current_user
      render json: {error: "Unauthorized"}, status: :unauthorized
    end
  end
end
