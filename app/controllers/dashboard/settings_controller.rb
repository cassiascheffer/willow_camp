module Dashboard
  class SettingsController < Dashboard::BaseController
    def show
      @tokens = Current.user.tokens.order(created_at: :desc)
      @token = UserToken.new
    end
  end
end
