module Posts
  class FeedController < ApplicationController
    include SecureDomainRedirect

    before_action :set_author, only: %i[show]

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

    private

    def set_author
      set_author_with_secure_redirect
    end
  end
end
