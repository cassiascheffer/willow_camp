module ApplicationHelper
  include Pagy::Frontend

  def sanitize_html_for_feed(html_content)
    ActionController::Base.helpers.sanitize(html_content,
      tags: %w[a b strong i em p h1 h2 h3 h4 h5 h6 ul ol li blockquote pre code img],
      attributes: %w[href src alt title])
  end

  def blog_title_for(author)
    author.blog_title.presence || "#{author.subdomain}.willow.camp"
  end
end
