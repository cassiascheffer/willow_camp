module Dashboard
  class BaseController < ApplicationController
    layout "dashboard"
    before_action :authenticate_user!
    before_action :set_author

    private

    def set_author
      @author = current_user
    end
  end
end
