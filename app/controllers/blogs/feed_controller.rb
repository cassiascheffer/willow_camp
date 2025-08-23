module Blogs
  class FeedController < Blogs::BaseController
    # Allow all browsers for feed access (for crawlers, feed readers, etc.)
    allow_browser versions: {chrome: 1, firefox: 1, safari: 1, edge: 1, opera: 1, ie: false}

    def show
      @posts = @author.posts.published
        .order(published_at: :desc, created_at: :desc)
        .limit(20)

      respond_to do |format|
        format.atom { render layout: false }
        format.rss { render layout: false }
        format.json { render layout: false }
      end
    end

    def subscribe
      # HTML subscription page for feeds
    end
  end
end
