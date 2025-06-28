xml.instruct! :xml, version: "1.0", encoding: "UTF-8"
xml.urlset xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9" do
  # Home page
  xml.url do
    xml.loc posts_url
    xml.lastmod @posts.first&.updated_at&.iso8601 || Time.current.iso8601
    xml.changefreq "daily"
    xml.priority "1.0"
  end

  # Tags page
  xml.url do
    xml.loc tags_url
    xml.lastmod @posts.first&.updated_at&.iso8601 || Time.current.iso8601
    xml.changefreq "weekly"
    xml.priority "0.8"
  end

  # Individual tag pages
  @author.posts.published.not_page.tag_counts.each do |tag|
    xml.url do
      xml.loc tag_url(tag.name)
      xml.lastmod @posts.tagged_with(tag.name).maximum(:updated_at)&.iso8601 || Time.current.iso8601
      xml.changefreq "weekly"
      xml.priority "0.6"
    end
  end

  # Individual posts
  @posts.each do |post|
    xml.url do
      xml.loc post_url(post.slug)
      xml.lastmod post.updated_at.iso8601
      xml.changefreq "monthly"
      xml.priority "0.9"
    end
  end
end
