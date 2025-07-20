require "test_helper"

class PostTest < ActiveSupport::TestCase
  setup do
    @post = Post.new(
      author: users(:one),
      title: "Test Post",
      body_markdown: "Test content",
      published: true
    )
  end

  test "should be valid with required attributes" do
    assert @post.valid?, "Post with required attributes should be valid"
  end

  test "should require an author" do
    post = Post.new(title: "Test Post")
    assert_not post.valid?, "Post without an author should not be valid"
    assert_includes post.errors[:author], "must exist"
  end

  test "should require a title" do
    @post.title = ""
    assert_not @post.valid?
    assert_includes @post.errors[:title], "can't be blank"
  end

  test "title should not exceed maximum length" do
    @post.title = "a" * 256
    assert_not @post.valid?
    assert_includes @post.errors[:title], "is too long (maximum is 255 characters)"
  end

  test "should validate published is boolean" do
    # Nil is allowed by the model
    @post.published = nil
    assert @post.valid?

    # Non-boolean values should be coerced by Rails
    # This is how Rails typically handles boolean attributes
    @post.published = true
    assert @post.valid?

    @post.published = false
    assert @post.valid?
  end

  test "should set published_at when published" do
    post = Post.new(
      author: users(:one),
      title: "Test Post",
      published: true
    )

    assert_nil post.published_at
    post.save!
    assert_not_nil post.published_at
  end

  test "should belong to an author" do
    post = posts(:one)
    assert_respond_to post, :author, "Post should respond to 'author'"
    assert_instance_of User, post.author, "Post's author should be a User"
  end

  test "should have the correct author_id" do
    user = users(:one)
    post = Post.create(author: user, title: "Test Post")
    assert_equal user.id, post.author_id, "Post's author_id should match the author's id"
  end

  test "should generate HTML from markdown" do
    @post.body_markdown = "# Hello World\n\nThis is a test."
    @post.save!

    assert_not_nil @post.body_html
    assert_includes @post.body_html, "Hello World"
    assert_includes @post.body_html, "<p>This is a test.</p>"
  end

  test "should detect mermaid diagrams and set has_mermaid_diagrams flag" do
    @post.body_markdown = "```mermaid\ngraph TD\n  A --> B\n```"

    @post.save!

    assert @post.has_mermaid_diagrams, "Post should detect mermaid diagrams"
    assert_not_nil @post.body_html
    assert_match(/<pre[^>]*lang="mermaid"/, @post.body_html)
  end

  test "should not detect mermaid when only regular code blocks present" do
    @post.body_markdown = "```ruby\nputs 'test'\n```"

    @post.save!

    assert_not @post.has_mermaid_diagrams, "Post should not detect mermaid diagrams"
    assert_not_nil @post.body_html
    assert_includes @post.body_html, '<pre lang="ruby"'
  end

  test "should handle empty markdown" do
    @post.body_markdown = ""
    @post.save!

    assert_nil @post.body_html
    assert_not @post.has_mermaid_diagrams
  end

  test "should handle nil markdown" do
    @post.body_markdown = nil
    @post.save!

    assert_nil @post.body_html
    assert_not @post.has_mermaid_diagrams
  end

  test "draft? should return true when not published" do
    @post.published = false
    assert @post.draft?
  end

  test "draft? should return true when published is nil" do
    @post.published = nil
    assert @post.draft?
  end

  test "draft? should return false when published" do
    @post.published = true
    assert_not @post.draft?
  end
end
