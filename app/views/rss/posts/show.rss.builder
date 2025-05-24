xml.instruct! :xml, version: "1.0"
xml.rss version: "2.0", "xmlns:atom": "http://www.w3.org/2005/Atom" do
  xml.channel do
    xml.title @author.blog_title.presence || "#{@author.name}'s Blog"
    xml.description "Latest posts from #{@author.name}"
    xml.link posts_url(subdomain: @author.subdomain)
    xml.language "en"
    xml.tag!("atom:link", href: rss_posts_url(format: :rss, subdomain: @author.subdomain), rel: "self", type: "application/rss+xml")

    @posts.each do |post|
      xml.item do
        xml.title post.title
        xml.description post.body_html
        xml.pubDate post.published_at.to_fs(:rfc822)
        xml.link post_url(post.slug, subdomain: @author.subdomain)
        xml.guid post_url(post.slug, subdomain: @author.subdomain)
      end
    end
  end
end
