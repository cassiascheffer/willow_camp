xml.instruct! :xml, version: "1.0", encoding: "UTF-8"
xml.feed xmlns: "http://www.w3.org/2005/Atom" do
  xml.id posts_url(url_options_for(@blog))
  xml.title blog_title_for(@blog)
  xml.updated @posts.first.published_at.iso8601 if @posts.present?

  xml.author do
    xml.name @blog.user.name
  end

  xml.link href: posts_atom_url(url_options_for(@blog).merge(format: :atom)), rel: "self", type: "application/atom+xml"
  xml.link href: posts_url(url_options_for(@blog)), rel: "alternate", type: "text/html"

  xml.subtitle "Latest posts from #{@blog.user.name}"

  @posts.each do |post|
    xml.entry do
      xml.id post_url(post.slug, url_options_for(@blog))
      xml.title post.title
      xml.link href: post_url(post.slug, url_options_for(@blog)), rel: "alternate", type: "text/html"
      xml.updated post.published_at.iso8601
      xml.summary post.meta_description.presence || "#{post.title} by #{@blog.user.name}", type: "text"

      xml.content sanitize_html_for_feed(post.body_content.to_s, request), type: "html"
    end
  end
end
