xml.instruct! :xml, version: "1.0", encoding: "UTF-8"
xml.urlset xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9" do
  # Home page
  xml.url do
    xml.loc posts_url
    xml.lastmod @most_recent_update.iso8601
    xml.changefreq "daily"
    xml.priority "1.0"
  end

  # Tags page
  xml.url do
    xml.loc tags_url
    xml.lastmod @most_recent_update.iso8601
    xml.changefreq "weekly"
    xml.priority "0.8"
  end

  # Individual tag pages (limited to top 50 most used tags)
  @tags_with_dates.each do |tag_data|
    xml.url do
      xml.loc tag_url(tag_data[:name])
      xml.lastmod tag_data[:last_modified]
      xml.changefreq "weekly"
      xml.priority "0.6"
    end
  end

  # Individual posts (limited to most recent 500)
  @posts.each do |post|
    xml.url do
      xml.loc post_url(post.slug)
      xml.lastmod post.updated_at.iso8601
      xml.changefreq "monthly"
      xml.priority "0.9"
    end
  end

  # Pages (posts with is_page=true)
  @pages.each do |page|
    xml.url do
      xml.loc post_url(page.slug)
      xml.lastmod page.updated_at.iso8601
      xml.changefreq "monthly"
      xml.priority "0.7"
    end
  end

  # RSS Feed
  xml.url do
    xml.loc posts_rss_url
    xml.lastmod @most_recent_update.iso8601
    xml.changefreq "hourly"
    xml.priority "0.5"
  end

  # Atom Feed
  xml.url do
    xml.loc posts_atom_url
    xml.lastmod @most_recent_update.iso8601
    xml.changefreq "hourly"
    xml.priority "0.5"
  end

  # JSON Feed
  xml.url do
    xml.loc posts_json_url
    xml.lastmod @most_recent_update.iso8601
    xml.changefreq "hourly"
    xml.priority "0.5"
  end

  # Subscribe page
  xml.url do
    xml.loc subscribe_url
    xml.lastmod Time.current.iso8601
    xml.changefreq "monthly"
    xml.priority "0.4"
  end
end
