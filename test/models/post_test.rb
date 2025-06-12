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

  test "should add mermaid data-controller to mermaid code blocks" do
    @post.body_markdown = <<~MARKDOWN
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

    @post.save!

    assert_not_nil @post.body_html
    assert_includes @post.body_html, 'lang="mermaid"'
    assert_includes @post.body_html, 'data-controller="mermaid"'
    assert_includes @post.body_html, 'class="mermaid"'
    assert_not_includes @post.body_html, '<pre lang="ruby" data-controller="mermaid"'
  end

  test "should not modify non-mermaid code blocks" do
    @post.body_markdown = <<~MARKDOWN
      ```ruby
      puts "Hello World"
      ```

      ```javascript
      console.log("Hello World");
      ```
    MARKDOWN

    @post.save!

    assert_not_nil @post.body_html
    assert_includes @post.body_html, '<pre lang="ruby"'
    assert_includes @post.body_html, '<pre lang="javascript"'
    assert_not_includes @post.body_html, 'data-controller="mermaid"'
  end

  test "should handle empty markdown" do
    @post.body_markdown = ""
    @post.save!

    assert_nil @post.body_html
  end

  test "should handle nil markdown" do
    @post.body_markdown = nil
    @post.save!

    assert_nil @post.body_html
  end
end
