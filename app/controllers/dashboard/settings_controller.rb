module Dashboard
  class SettingsController < Dashboard::BaseController
    def show
      @tokens = current_user.tokens.order(created_at: :desc)
      @about_page = current_user.pages.find_or_initialize_by(slug: "about")
      @token = UserToken.new
    end
  end
end
