module Posts
  class FeedController < ApplicationController
    allow_unauthenticated_access only: %i[show]
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
      @author = User.find_by(subdomain: request.subdomain)
      if @author.nil?
        redirect_to root_url(subdomain: false), allow_other_host: true
      end
    end
  end
end
