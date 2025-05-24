xml.instruct! :xml, version: "1.0", encoding: "UTF-8"
xml.feed xmlns: "http://www.w3.org/2005/Atom" do
  xml.id posts_url(subdomain: @author.subdomain)
  xml.title @author.blog_title.presence || "#{@author.name}'s Blog"
  xml.updated @posts.first.published_at.iso8601 if @posts.present?

  xml.author do
    xml.name @author.name
  end

  xml.link href: atom_posts_url(format: :atom, subdomain: @author.subdomain), rel: "self", type: "application/atom+xml"
  xml.link href: posts_url(subdomain: @author.subdomain), rel: "alternate", type: "text/html"

  xml.subtitle "Latest posts from #{@author.name}"

  @posts.each do |post|
    xml.entry do
      xml.id post_url(post.slug, subdomain: @author.subdomain)
      xml.title post.title
      xml.link href: post_url(post.slug, subdomain: @author.subdomain), rel: "alternate", type: "text/html"
      xml.updated post.published_at.iso8601
      xml.summary post.meta_description.presence || "#{post.title} by #{@author.name}", type: "text"

      xml.content ActionController::Base.helpers.sanitize(post.body_html,
        tags: %w[a b strong i em p h1 h2 h3 h4 h5 h6 ul ol li blockquote pre code img],
        attributes: %w[href src alt title]), type: "html"
    end
  end
end
