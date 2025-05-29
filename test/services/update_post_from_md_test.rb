require "test_helper"

class UpdatePostFromMdTest < ActiveSupport::TestCase
  test "creates a post from markdown file with frontmatter" do
    author = users(:one)
    markdown_content = <<~MARKDOWN
      ---
      title: Test Post
      meta_description: This is a test post
      published: true
      published_at: 2023-01-01
      tags:
        - ruby
        - rails
      ---
      
      # Test Post Content
      
      This is the body of the test post.
    MARKDOWN
    post = author.posts.build

    post = UpdatePostFromMd.new(markdown_content, post).call

    assert_equal "Test Post", post.title
    assert_equal "This is a test post", post.meta_description
    assert_equal true, post.published
    assert_equal "2023-01-01", post.published_at.to_date.to_s
    assert_equal "ruby, rails", post.tag_list.to_s
    assert_equal "# Test Post Content\n\nThis is the body of the test post.", post.body_markdown.strip
    assert_equal author, post.author
  end

  test "handles missing frontmatter gracefully" do
    author = users(:one)
    post = author.posts.build
    markdown_content = "# Just Content\n\nNo frontmatter here."

    post = UpdatePostFromMd.new(markdown_content, post).call

    assert_nil post.title
    assert_equal markdown_content, post.body_markdown
    assert_equal author, post.author
  end

  test "handles syntax errors in frontmatter" do
    author = users(:one)
    post = author.posts.build

    # Invalid frontmatter format (missing closing ---)
    markdown_content = <<~MARKDOWN
      ---
      title: Bad Frontmatter
      
      # Content
      
      Some content here.
    MARKDOWN

    post = UpdatePostFromMd.new(markdown_content, post).call

    assert_nil post.title
    assert_equal markdown_content, post.body_markdown
    assert_equal author, post.author
  end

  test "adds an error to post if markdown content is blank" do
    author = users(:one)
    post = author.posts.build

    post = UpdatePostFromMd.new("", post).call
    assert_equal post.errors[:base], ["No content provided"]

    post.errors.clear

    post = UpdatePostFromMd.new(nil, post).call
    assert_equal post.errors[:base], ["No content provided"]
  end

  test "returns nil if post is nil" do
    markdown_content = "# Test\n\nSome content."

    post = UpdatePostFromMd.new(markdown_content, nil).call
    assert_nil post
  end

  test "handles Date objects in frontmatter" do
    author = users(:one)
    post = author.posts.build
    # Frontmatter with explicit date type that would cause the DisallowedClass error
    markdown_content = <<~MARKDOWN
      ---
      title: Date Test Post
      meta_description: This post tests handling of dates
      published: true
      published_at: 2025-05-25
      tags:
        - ruby
        - rails
      ---
      
      # Date Test Content
      
      This post tests proper handling of Date objects in frontmatter.
    MARKDOWN

    post = UpdatePostFromMd.new(markdown_content, post).call

    assert_equal "Date Test Post", post.title
    assert_equal "This post tests handling of dates", post.meta_description
    assert_equal true, post.published
    assert_not_nil post.published_at
    assert_equal "2025-05-25", post.published_at.to_date.to_s
    assert_equal "ruby, rails", post.tag_list.to_s
  end
end
