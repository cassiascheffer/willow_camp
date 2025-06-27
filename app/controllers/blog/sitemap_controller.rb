class Blog::SitemapController < Blog::BaseController
  # Allow all browsers for sitemap access (for crawlers, search engines, etc.)
  allow_browser versions: {chrome: 1, firefox: 1, safari: 1, edge: 1, opera: 1, ie: false}

  def show
    @posts = @author.posts.published.not_page.order(published_at: :desc)

    respond_to :xml
    expires_in 6.hours, public: true
  end
end
