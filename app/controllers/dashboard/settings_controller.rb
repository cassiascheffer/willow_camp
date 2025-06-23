module Dashboard
  class SettingsController < Dashboard::BaseController
    def show
      @user = current_user
      @tokens = @user.tokens.order(created_at: :desc)
      @about_page = @user.pages.find_or_create_by(title: "About", slug: "about")
      @token = UserToken.new
    end
  end
end
