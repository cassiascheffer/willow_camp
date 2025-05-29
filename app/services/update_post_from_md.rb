# Service to update a Post from a markdown file with frontmatter
class UpdatePostFromMd
  # Initializes the service with the provided markdown content and optional author
  #
  # @param markdown_content [String] Content of the markdown file including frontmatter
  # @param post [Post] The post to update (required)
  def initialize(markdown_content, post)
    @markdown_content = markdown_content
    @frontmatter = {}
    @post = post
  end

  # Creates and returns a new Post instance based on the markdown content
  #
  # @return [Post] A new Post instance with attributes set from frontmatter
  def call
    return nil if @post.nil?
    if @markdown_content.blank?
      @post.errors.add(:base, "No content provided")
      return @post
    end

    parse_frontmatter
    update_post
  end

  private

  def parse_frontmatter
    parsed = parser.call(@markdown_content)
    @frontmatter = parsed.front_matter || {}
    @content = parsed.content
  rescue YAML::SyntaxError => e
    @post.errors.add(:base, "frontmatter is invalid: #{e.message}")
    @frontmatter = {}
    @content = @markdown_content
  end

  def update_post
    @post.tap do |p|
      p.body_markdown = @content
      p.title = @frontmatter["title"]
      p.slug = @frontmatter["slug"]
      p.meta_description = @frontmatter["meta_description"]
      p.published = @frontmatter["published"]
      p.published_at = @frontmatter["published_at"]
      p.tag_list = @frontmatter["tags"].presence&.join(", ")
    end
  end

  def yaml_loader
    FrontMatterParser::Loader::Yaml.new(allowlist_classes: [Date, Time, DateTime])
  end

  def parser
    FrontMatterParser::Parser.new(:md, loader: yaml_loader)
  end
end
