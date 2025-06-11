module Dashboard
  class BaseController < ApplicationController
    layout "dashboard"
    before_action :authenticate_user!
  end
end
