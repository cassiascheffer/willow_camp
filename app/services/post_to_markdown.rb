# Service to convert a Post to a markdown file with frontmatter
class PostToMarkdown
  # Initializes the service with the provided post
  #
  # @param post [Post] Post to convert to markdown
  def initialize(post)
    @post = post
  end

  # Creates and returns markdown content with frontmatter for the post
  #
  # @return [String] Markdown content with frontmatter
  def call
    return nil if @post.nil?

    frontmatter = build_frontmatter
    content = @post.body_markdown || ""

    "#{frontmatter}#{content}"
  end

  private

  def build_frontmatter
    frontmatter = {
      "title" => @post.title,
      "slug" => @post.slug,
      "meta_description" => @post.meta_description,
      "published" => @post.published,
      "published_at" => @post.published_at
    }

    # Add tags if present
    frontmatter["tags"] = @post.tag_list if @post.tag_list.present?

    # Convert to YAML frontmatter
    yaml = frontmatter.compact.to_yaml
    "---\n#{yaml}---\n\n"
  end
end
