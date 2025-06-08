module Dashboard
  class SettingsController < Dashboard::BaseController
    def show
      @tokens = user.tokens.order(created_at: :desc)
      @about_page = user.pages.find_or_initialize_by(slug: "about")
      @token = UserToken.new
    end

    private

    def user
      Current.user
    end
  end
end
