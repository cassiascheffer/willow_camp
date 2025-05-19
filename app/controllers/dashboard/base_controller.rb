module Dashboard
  class BaseController < ApplicationController
    layout "dashboard"
    before_action :set_user

    private
      def set_user
        @user = Current.user

        if @user.nil?
          redirect_to root_path, alert: "Please log in to access your dashboard."
        end
      end
  end
end
