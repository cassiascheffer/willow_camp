require "test_helper"

class PostMarkdownTest < ActiveSupport::TestCase
  test "should return nil for blank markdown" do
    post_markdown = PostMarkdown.new("")
    assert_nil post_markdown.to_html

    post_markdown = PostMarkdown.new(nil)
    assert_nil post_markdown.to_html

    post_markdown = PostMarkdown.new("   ")
    assert_nil post_markdown.to_html
  end

  test "should convert basic markdown to HTML" do
    markdown = "# Hello World\n\nThis is a test."
    post_markdown = PostMarkdown.new(markdown)
    html = post_markdown.to_html

    assert_not_nil html
    assert_includes html, "Hello World"
    assert_includes html, "<p>This is a test.</p>"
  end

  test "should add mermaid class to mermaid code blocks" do
    markdown = <<~MARKDOWN
      # Test Post

      Here's a mermaid diagram:

      ```mermaid
      graph TD
        A --> B
      ```

      And here's regular code:

      ```ruby
      puts "Hello World"
      ```
    MARKDOWN

    post_markdown = PostMarkdown.new(markdown)
    html = post_markdown.to_html

    assert_not_nil html
    assert_includes html, 'lang="mermaid"'
    assert_includes html, 'class="mermaid"'
    assert_not_includes html, '<pre lang="ruby" class="mermaid"'
  end

  test "should not modify non-mermaid code blocks" do
    markdown = <<~MARKDOWN
      ```ruby
      puts "Hello World"
      ```

      ```javascript
      console.log("Hello World");
      ```

      ```python
      print("Hello World")
      ```
    MARKDOWN

    post_markdown = PostMarkdown.new(markdown)
    html = post_markdown.to_html

    assert_not_nil html
    assert_includes html, '<pre lang="ruby"'
    assert_includes html, '<pre lang="javascript"'
    assert_includes html, '<pre lang="python"'
    assert_not_includes html, 'class="mermaid"'
  end

  test "should handle multiple mermaid blocks" do
    markdown = <<~MARKDOWN
      First diagram:

      ```mermaid
      graph TD
        A --> B
      ```

      Second diagram:

      ```mermaid
      flowchart LR
        C --> D
      ```
    MARKDOWN

    post_markdown = PostMarkdown.new(markdown)
    html = post_markdown.to_html

    assert_not_nil html
    # Should have two mermaid blocks with class="mermaid"
    mermaid_blocks = html.scan('class="mermaid"')
    assert_equal 2, mermaid_blocks.length
  end

  test "should preserve other HTML formatting" do
    markdown = <<~MARKDOWN
      # Header

      **Bold text** and *italic text*.

      - List item 1
      - List item 2

      [Link](https://example.com)
    MARKDOWN

    post_markdown = PostMarkdown.new(markdown)
    html = post_markdown.to_html

    assert_not_nil html
    assert_includes html, "<strong>Bold text</strong>"
    assert_includes html, "<em>italic text</em>"
    assert_includes html, "<ul>"
    assert_includes html, "<li>List item 1</li>"
    assert_includes html, '<a href="https://example.com">Link</a>'
  end

  test "should handle footnotes extension" do
    markdown = <<~MARKDOWN
      This is text with a footnote[^1].

      [^1]: This is the footnote.
    MARKDOWN

    post_markdown = PostMarkdown.new(markdown)
    html = post_markdown.to_html

    assert_not_nil html
    # Footnotes should be processed by commonmarker
    assert_includes html, "footnote"
  end

  test "should handle smart quotes" do
    markdown = 'He said "Hello" and she replied \'Hi\'.'
    post_markdown = PostMarkdown.new(markdown)
    html = post_markdown.to_html

    assert_not_nil html
    # Smart quotes should be processed
    assert_includes html, "Hello"
    assert_includes html, "Hi"
  end

  test "to_s should return markdown content as string" do
    markdown = "# Hello World"
    post_markdown = PostMarkdown.new(markdown)
    assert_equal markdown, post_markdown.to_s
  end

  test "to_s should handle nil content" do
    post_markdown = PostMarkdown.new(nil)
    assert_equal "", post_markdown.to_s
  end

  test "present? should return true for content with text" do
    post_markdown = PostMarkdown.new("# Hello")
    assert post_markdown.present?
  end

  test "present? should return false for blank content" do
    post_markdown = PostMarkdown.new("")
    assert_not post_markdown.present?

    post_markdown = PostMarkdown.new(nil)
    assert_not post_markdown.present?

    post_markdown = PostMarkdown.new("   ")
    assert_not post_markdown.present?
  end

  test "blank? should return true for blank content" do
    post_markdown = PostMarkdown.new("")
    assert post_markdown.blank?

    post_markdown = PostMarkdown.new(nil)
    assert post_markdown.blank?

    post_markdown = PostMarkdown.new("   ")
    assert post_markdown.blank?
  end

  test "blank? should return false for content with text" do
    post_markdown = PostMarkdown.new("# Hello")
    assert_not post_markdown.blank?
  end
end
