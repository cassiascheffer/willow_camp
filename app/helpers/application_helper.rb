module ApplicationHelper
  ALL_THEMES = %w[light dark abyss acid aqua autumn black bumblebee business caramellatte cmyk coffee corporate cupcake cyberpunk dim dracula emerald fantasy forest garden halloween lemonade lofi luxury night nord pastel retro silk sunset synthwave valentine vineframe winter].freeze

  def render_markdown_with_frontmatter(post)
    PostToMarkdown.new(post).call
  end

  def sanitize_html_for_feed(html_content, request = nil)
    host = request&.host || Rails.application.config.action_controller.default_url_options[:host]
    port = request&.port
    protocol = request&.protocol || "https://"

    # First sanitize the content
    sanitized = ActionController::Base.helpers.sanitize(html_content,
      tags: %w[a b strong i em p h1 h2 h3 h4 h5 h6 ul ol li blockquote pre code img],
      attributes: %w[href src alt title])

    # Convert all relative URLs to absolute URLs using Nokogiri
    doc = Nokogiri::HTML::DocumentFragment.parse(sanitized)

    # Convert anchor links in href attributes
    doc.css("a[href]").each do |link|
      href = link["href"]
      next unless href.start_with?("#")

      # Create an absolute URL by removing the anchor and adding it back
      # This effectively converts "#section" to "https://example.com/path#section"
      request_path = request&.path || "/"
      base_url = "#{protocol}#{host}"
      base_url += ":#{port}" if port && port != 80 && port != 443
      link["href"] = "#{base_url}#{request_path}#{href}"
    end

    doc.to_html
  end

  def blog_title_for(blog)
    return "willow.camp" if blog.nil? || (blog.subdomain.blank? && blog.custom_domain.blank?)
    blog.title.presence || blog.domain || "willow.camp"
  end

  def url_options_for(blog)
    return {} if blog.nil?

    if blog.uses_custom_domain?
      {host: blog.custom_domain}
    elsif blog.subdomain.present?
      {subdomain: blog.subdomain}
    else
      {}
    end
  end

  def emoji_to_openmoji_filename(emoji)
    return "1F3D5" if emoji.blank? # Default camping emoji

    # Convert emoji to hex codepoint(s), excluding variation selectors
    emoji.codepoints
      .reject { |cp| cp == 0xFE0F || cp == 0xFE0E } # Skip variation selectors
      .map { |cp| cp.to_s(16).upcase }
      .join("-")
  end

  def blog_nav_title(blog)
    blog ? (blog.title.presence || blog.subdomain) : "willow.camp"
  end

  def blog_nav_path(blog)
    blog ? dashboard_blog_path(blog.subdomain) : dashboard_path
  end
end
