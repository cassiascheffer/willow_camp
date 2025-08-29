module Dashboard
  class BaseController < ApplicationController
    layout "dashboard"
    before_action :authenticate_user!
    before_action :set_author
    before_action :set_default_blog

    private

    def set_author
      @author = current_user
    end

    def set_default_blog
      @blog = current_user&.blogs&.find_by(primary: true) || current_user&.blogs&.first
    end
  end
end
