module Dashboard
  class SettingsController < Dashboard::BaseController
    def show
      @tokens = @user.tokens
      @token = UserToken.new
    end
  end
end
