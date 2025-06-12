module ApplicationHelper
  include Pagy::Frontend

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

  def blog_title_for(author)
    return "willow.camp" if author.nil? || author.subdomain.blank?
    author.blog_title.presence || "#{author.subdomain}.willow.camp"
  end

  # Generate social share image HTML for a post
  def social_share_image_for(post, options = {})
    return "" unless post&.author

    data_attributes = {
      controller: "social-share-image",
      "social-share-image-title-value": post.title,
      "social-share-image-author-value": post.author_name,
      "social-share-image-favicon-value": post.author.favicon_emoji || "⛺",
      "social-share-image-blog-title-value": blog_title_for(post.author)
    }.merge(options.fetch(:data, {}))

    css_classes = ["social-share-generator"]
    css_classes += Array(options[:class]) if options[:class]

    content_tag :div, "",
      data: data_attributes,
      class: css_classes.join(" "),
      style: options.fetch(:style, "display: none;")
  end

  # Generate social share image preview with controls
  def social_share_image_preview_for(post, options = {})
    return "" unless post&.author

    data_attributes = {
      controller: "social-share-image",
      "social-share-image-title-value": post.title,
      "social-share-image-author-value": post.author_name,
      "social-share-image-favicon-value": post.author.favicon_emoji || "⛺",
      "social-share-image-blog-title-value": blog_title_for(post.author)
    }

    content_tag :div, data: data_attributes, class: "social-share-preview" do
      content_tag(:div, class: "mb-4") do
        content_tag(:p, "This is how your post will appear when shared on social media:",
          class: "text-sm text-base-content/70 mb-4") +
          content_tag(:div, "",
            data: {"social-share-image-target": "canvas"},
            class: "social-share-canvas-container")
      end +
        content_tag(:div, class: "flex gap-2") do
          content_tag(:button, "Regenerate Image",
            data: {action: "click->social-share-image#regenerate"},
            class: "btn btn-outline btn-sm") +
            content_tag(:a, "Download Image",
              href: "#",
              download: "#{post.slug}-social-share.png",
              data: {"social-share-image-target": "downloadLink"},
              class: "btn btn-primary btn-sm")
        end
    end
  end
end
