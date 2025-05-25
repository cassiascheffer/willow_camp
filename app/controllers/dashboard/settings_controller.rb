module Dashboard
  class SettingsController < Dashboard::BaseController
    def show
      @user = Current.user
      @tokens = Current.user.tokens.order(created_at: :desc)
      @token = UserToken.new
    end
  end
end
