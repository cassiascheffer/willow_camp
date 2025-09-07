class Blogs::SitemapController < Blogs::BaseController
  # Allow all browsers for sitemap access (for crawlers, search engines, etc.)
  allow_browser versions: {chrome: 1, firefox: 1, safari: 1, edge: 1, opera: 1, ie: false}

  def show
    # Limit posts to most recent 500 to prevent performance issues
    @posts = @blog.posts.published.not_page.order(published_at: :desc).limit(500)
    @pages = @blog.pages.published.order(published_at: :desc)

    # Get tags with their last modified dates (top 50 most used)
    # First get the top tags
    top_tags = @blog.posts.published.not_page.tag_counts.limit(50)

    # Then get last modified dates for all tags in one query
    tag_names = top_tags.map(&:name)
    tag_last_modified = {}

    if tag_names.any?
      # Get all posts with these tags and their update times
      tag_updates = @blog.posts.published.not_page
        .joins(:taggings)
        .joins("INNER JOIN tags ON tags.id = taggings.tag_id")
        .where(tags: {name: tag_names})
        .group("tags.name")
        .maximum(:updated_at)

      tag_last_modified = tag_updates.transform_values { |date| date&.iso8601 || Time.current.iso8601 }
    end

    @tags_with_dates = top_tags.map do |tag|
      {
        name: tag.name,
        count: tag.count,
        last_modified: tag_last_modified[tag.name] || Time.current.iso8601
      }
    end

    # Get the most recent update time for feeds
    @most_recent_update = @posts.maximum(:updated_at) || Time.current

    respond_to :xml
    expires_in 6.hours, public: true
  end
end
