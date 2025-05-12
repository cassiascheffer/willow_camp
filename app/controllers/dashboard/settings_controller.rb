class Dashboard::SettingsController < Dashboard::BaseController
  def show
    @tokens = @user.tokens
    @token = UserToken.new
  end
end
