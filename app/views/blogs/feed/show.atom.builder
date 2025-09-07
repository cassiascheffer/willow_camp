xml.instruct! :xml, version: "1.0", encoding: "UTF-8"
xml.feed xmlns: "http://www.w3.org/2005/Atom" do
  xml.id posts_url(url_options_for(@author))
  xml.title blog_title_for(@author)
  xml.updated @posts.first.published_at.iso8601 if @posts.present?

  xml.author do
    xml.name @author.name
  end

  xml.link href: posts_atom_url(url_options_for(@author).merge(format: :atom)), rel: "self", type: "application/atom+xml"
  xml.link href: posts_url(url_options_for(@author)), rel: "alternate", type: "text/html"

  xml.subtitle "Latest posts from #{@author.name}"

  @posts.each do |post|
    xml.entry do
      xml.id post_url(post.slug, url_options_for(@author))
      xml.title post.title
      xml.link href: post_url(post.slug, url_options_for(@author)), rel: "alternate", type: "text/html"
      xml.updated post.published_at.iso8601
      xml.summary post.meta_description.presence || "#{post.title} by #{@author.name}", type: "text"

      xml.content sanitize_html_for_feed(post.body_html, request), type: "html"
    end
  end
end
