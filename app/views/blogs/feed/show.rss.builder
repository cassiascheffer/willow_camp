xml.instruct! :xml, version: "1.0"
xml.rss version: "2.0", "xmlns:atom": "http://www.w3.org/2005/Atom" do
  xml.channel do
    xml.title blog_title_for(@author)
    xml.description "Latest posts from #{@author.name}"
    xml.link posts_url(url_options_for(@author))
    xml.language "en"
    xml.tag!("atom:link", href: posts_rss_url(url_options_for(@author).merge(format: :rss)), rel: "self", type: "application/rss+xml")

    @posts.each do |post|
      xml.item do
        xml.title post.title
        xml.description sanitize_html_for_feed(post.body_html, request)
        xml.pubDate post.published_at.to_fs(:rfc822)
        xml.link post_url(post.slug, url_options_for(@author))
        xml.guid post_url(post.slug, url_options_for(@author))
      end
    end
  end
end
