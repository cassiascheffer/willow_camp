class Blogs::RobotsController < Blogs::BaseController
  # Allow all browsers for robots.txt access (for crawlers, search engines, etc.)
  allow_browser versions: {chrome: 1, firefox: 1, safari: 1, edge: 1, opera: 1, ie: false}

  def show
    @sitemap_url = sitemap_url(format: :xml)

    respond_to :text
    expires_in 30.days, public: true
  end
end
