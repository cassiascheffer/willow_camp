# PostMarkdown represents markdown content with the ability to convert to HTML
# with special handling for mermaid diagrams
class PostMarkdown
  delegate :to_s, :present?, :blank?, to: :@content
  # Initializes with markdown content
  #
  # @param content [String] The markdown content
  def initialize(content)
    @content = content
  end

  # Converts the markdown content to HTML
  #
  # @return [String, nil] HTML content or nil if markdown is blank
  def to_html
    return nil if @content.blank?

    html = render_markdown_to_html
    process_mermaid_blocks(html)
  end

  private

  def render_markdown_to_html
    Commonmarker.parse(@content, options: {
      extension: {footnotes: true},
      parse: {smart: true}
    }).to_html
  end

  def process_mermaid_blocks(html)
    # Add mermaid controller to pre elements with mermaid lang
    html.gsub('<pre lang="mermaid"') do |match|
      '<pre lang="mermaid" data-controller="mermaid" class="mermaid"'
    end
  end
end
