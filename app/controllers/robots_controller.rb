class RobotsController < ApplicationController
  # Allow all browsers for robots.txt access (for crawlers, search engines, etc.)
  allow_browser versions: {chrome: 1, firefox: 1, safari: 1, edge: 1, opera: 1, ie: false}

  def show
    respond_to :text
    expires_in 30.days, public: true
  end
end
