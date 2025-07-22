require "test_helper"

module WillowCampCLI
  class LinkCleanupTest < Minitest::Test
    def setup
      @cli = CLI.new({})
    end

    def test_clean_malformed_links_with_multiline_content
      malformed_markdown = <<~MARKDOWN
        Here's some content with a malformed link:

        [

        GitHub - cassidycodes/schema-stitching-basics: GraphQL tools schema stitching basics

        GraphQL tools schema stitching basics. Contribute to cassidycodes/schema-stitching-basics development by creating an account on GitHub.

         ![](  /content/images/icon/pinned-octocat-093da3e6fa40.svg)GitHubcassidycodes

         ![](  /content/images/thumbnail/schema-stitching-basics)
        ](https://github.com/cassidycodes/schema-stitching-basics)

        This should remain unchanged: [Normal Link](https://example.com)
      MARKDOWN

      expected_result = <<~MARKDOWN
        Here's some content with a malformed link:

        [GitHub - cassidycodes/schema-stitching-basics: GraphQL tools schema stitching basics](https://github.com/cassidycodes/schema-stitching-basics)

        This should remain unchanged: [Normal Link](https://example.com)
      MARKDOWN

      result = @cli.send(:clean_malformed_links, malformed_markdown)
      assert_equal expected_result.strip, result.strip
    end

    def test_clean_malformed_links_with_multiple_links
      malformed_markdown = <<~MARKDOWN
        [

        First Repository Title

        Description text here with more details.

         ![](image1.png)
        ](https://github.com/user/repo1)

        Some text in between.

        [

        Second Repository Title

        Another description with images.

         ![](image2.png)
         ![](image3.png)
        ](https://github.com/user/repo2)
      MARKDOWN

      expected_result = <<~MARKDOWN
        [First Repository Title](https://github.com/user/repo1)

        Some text in between.

        [Second Repository Title](https://github.com/user/repo2)
      MARKDOWN

      result = @cli.send(:clean_malformed_links, malformed_markdown)
      assert_equal expected_result.strip, result.strip
    end

    def test_clean_malformed_links_preserves_normal_links
      normal_markdown = <<~MARKDOWN
        This is normal text with [a regular link](https://example.com).

        Here's another [inline link](https://github.com/user/repo) that should not change.

        And here's a [link with title](https://example.com "Title") that should also remain.
      MARKDOWN

      result = @cli.send(:clean_malformed_links, normal_markdown)
      assert_equal normal_markdown, result
    end

    def test_clean_malformed_links_handles_empty_content
      result = @cli.send(:clean_malformed_links, "")
      assert_equal "", result
    end

    def test_clean_malformed_links_handles_no_links
      markdown = <<~MARKDOWN
        This is just regular text with no links.

        Some more text here.

        And a paragraph with **bold** and *italic* text.
      MARKDOWN

      result = @cli.send(:clean_malformed_links, markdown)
      assert_equal markdown, result
    end

    def test_clean_malformed_links_with_complex_title
      malformed_markdown = <<~MARKDOWN
        [

        Complex Title: With Colons & Special Characters!

        Long description that spans multiple lines
        and contains various details about the content.

         ![](complex-image.png)
         More text after image
        ](https://example.com/complex-url)
      MARKDOWN

      expected_result = "[Complex Title: With Colons & Special Characters!](https://example.com/complex-url)"

      result = @cli.send(:clean_malformed_links, malformed_markdown)
      assert_equal expected_result, result.strip
    end

    def test_clean_malformed_links_with_https_and_http_urls
      malformed_markdown = <<~MARKDOWN
        [

        HTTPS Link Title

        Description here.
        ](https://secure.example.com/path)

        [

        HTTP Link Title

        Another description.
        ](http://example.com/path)
      MARKDOWN

      expected_result = <<~MARKDOWN
        [HTTPS Link Title](https://secure.example.com/path)

        [HTTP Link Title](http://example.com/path)
      MARKDOWN

      result = @cli.send(:clean_malformed_links, malformed_markdown)
      assert_equal expected_result.strip, result.strip
    end

    def test_clean_malformed_links_preserves_context_around_links
      malformed_markdown = <<~MARKDOWN
        Here's some intro text.

        [

        Link Title

        Description with details.
        ](https://example.com)

        Here's some text after the link.

        ## A heading

        More content here.
      MARKDOWN

      expected_result = <<~MARKDOWN
        Here's some intro text.

        [Link Title](https://example.com)

        Here's some text after the link.

        ## A heading

        More content here.
      MARKDOWN

      result = @cli.send(:clean_malformed_links, malformed_markdown)
      assert_equal expected_result.strip, result.strip
    end
  end
end
