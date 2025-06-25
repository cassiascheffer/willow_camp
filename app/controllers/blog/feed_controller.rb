module Blog
  class FeedController < Blog::BaseController
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
  end
end
