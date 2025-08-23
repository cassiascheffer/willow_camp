require "test_helper"

class PostTest < ActiveSupport::TestCase
  include ActionDispatch::TestProcess::FixtureFile
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

  # Social Share Image Tests
  test "should have social_share_image attachment" do
    assert_respond_to @post, :social_share_image
  end

  test "should be able to attach image" do
    @post.save!
    image_file = fixture_file_upload("test_image.png", "image/png")

    @post.social_share_image.attach(image_file)

    assert @post.social_share_image.attached?
  end

  test "should return false for attached? when no image" do
    @post.save!
    assert_not @post.social_share_image.attached?
  end

  test "should save successfully with attached image" do
    image_file = fixture_file_upload("test_image.png", "image/png")
    @post.social_share_image.attach(image_file)

    assert @post.save
    assert @post.social_share_image.attached?
  end

  test "should save successfully without attached image" do
    assert @post.save
    assert_not @post.social_share_image.attached?
  end

  # Blog Association Tests
  test "should belong to a blog (optional)" do
    assert_respond_to @post, :blog
    assert @post.valid? # Should be valid without blog for backwards compatibility
  end

  test "should be valid with a blog" do
    user = users(:one)
    blog = Blog.create!(
      user: user,
      subdomain: "testblog",
      favicon_emoji: "🚀"
    )
    @post.blog = blog
    assert @post.valid?
    @post.save!
    assert_equal blog, @post.blog
  end

  test "should use blog scope for friendly_id" do
    user = users(:one)
    blog1 = Blog.create!(
      user: user,
      subdomain: "blog1",
      favicon_emoji: "🚀"
    )
    blog2 = Blog.create!(
      user: user,
      subdomain: "blog2",
      favicon_emoji: "🎯"
    )

    # Posts with same title in different blogs should have same slug
    post1 = blog1.posts.create!(
      title: "Same Title",
      body_markdown: "Content 1",
      author: user
    )
    post2 = blog2.posts.create!(
      title: "Same Title",
      body_markdown: "Content 2",
      author: user
    )

    assert_equal "same-title", post1.slug
    assert_equal "same-title", post2.slug
    assert_not_equal post1.id, post2.id
  end

  test "should use author_id for acts_as_taggable_tenant" do
    user = users(:one)

    @post.author = user
    @post.tag_list = ["ruby", "rails"]
    @post.save!

    # Verify tags are scoped to user (author)
    assert_equal ["rails", "ruby"], @post.tag_list.sort

    # Check that the tag tenant is the user's ID
    tag = @post.tags.first
    tagging = tag.taggings.where(taggable: @post).first
    assert_equal user.id, tagging.tenant
  end

  # Backwards Compatibility Tests
  test "should create post without blog (backwards compatibility)" do
    user = users(:one)
    post = user.posts.build(
      title: "Legacy Post",
      body_markdown: "This post has no blog",
      published: true
    )

    assert_nil post.blog
    assert_nil post.blog_id
    assert post.valid?, "Post should be valid without a blog"
    assert post.save, "Post should save without a blog"

    # Verify it was created without blog
    saved_post = Post.find(post.id)
    assert_nil saved_post.blog_id
    assert_equal user, saved_post.author
  end

  test "should handle tagging for posts without blog (backwards compatibility)" do
    user = users(:one)
    post = user.posts.create!(
      title: "Legacy Tagged Post",
      body_markdown: "Legacy content",
      tag_list: ["legacy", "test"]
    )

    assert_nil post.blog_id
    assert_equal ["legacy", "test"], post.tag_list.sort

    # Tags should still work even without blog_id
    assert post.tags.any?
    assert_equal 2, post.tags.count
  end

  test "should allow multiple posts with same slug when blog_id is nil (backwards compatibility)" do
    user = users(:one)

    # Create two posts with same title but no blog
    post1 = user.posts.create!(
      title: "Same Title",
      body_markdown: "Content 1"
    )
    post2 = user.posts.create!(
      title: "Same Title",
      body_markdown: "Content 2"
    )

    assert_nil post1.blog_id
    assert_nil post2.blog_id
    assert_equal "same-title", post1.slug
    assert_equal "same-title-2", post2.slug # FriendlyId should sequence
  end

  # Test Post.from_markdown backwards compatibility
  test "from_markdown should work with User (legacy signature)" do
    user = users(:one)
    markdown = <<~MARKDOWN
      ---
      title: "Legacy Post"
      published: true
      tags: ["ruby", "legacy"]
      ---
      
      This is legacy content.
    MARKDOWN

    post = Post.from_markdown(markdown, user)

    assert_not_nil post
    assert_equal "Legacy Post", post.title
    assert_equal user, post.author
    assert_nil post.blog # Should be nil for legacy signature
    assert post.published
    assert_equal ["legacy", "ruby"], post.tag_list.sort
  end

  test "from_markdown should work with Blog (new signature)" do
    user = users(:one)
    blog = Blog.create!(
      user: user,
      subdomain: "testblog",
      favicon_emoji: "🚀"
    )

    markdown = <<~MARKDOWN
      ---
      title: "New Post"
      published: true
      tags: ["ruby", "modern"]
      ---
      
      This is modern content.
    MARKDOWN

    post = Post.from_markdown(markdown, blog, user)

    assert_not_nil post
    assert_equal "New Post", post.title
    assert_equal user, post.author
    assert_equal blog, post.blog
    assert post.published
    assert_equal ["modern", "ruby"], post.tag_list.sort
  end

  test "from_markdown should handle Blog without explicit author" do
    user = users(:one)
    blog = Blog.create!(
      user: user,
      subdomain: "testblog",
      favicon_emoji: "🚀"
    )

    markdown = <<~MARKDOWN
      ---
      title: "Auto Author Post"
      published: true
      ---
      
      Author should be inferred from blog.
    MARKDOWN

    post = Post.from_markdown(markdown, blog) # No explicit author

    assert_not_nil post
    assert_equal "Auto Author Post", post.title
    assert_equal user, post.author # Should use blog.user
    assert_equal blog, post.blog
  end

  test "should maintain unique constraint with mixed blog_id scenarios" do
    user = users(:one)
    blog = Blog.create!(
      user: user,
      subdomain: "mixedblog",
      favicon_emoji: "🚀"
    )

    # Create post without blog
    legacy_post = user.posts.create!(
      title: "Mixed Scenario",
      slug: "mixed-scenario"
    )

    # Create post with blog - same slug should be allowed
    modern_post = blog.posts.create!(
      title: "Mixed Scenario",
      slug: "mixed-scenario",
      author: user
    )

    assert_nil legacy_post.blog_id
    assert_equal blog.id, modern_post.blog_id
    assert_equal "mixed-scenario", legacy_post.slug
    assert_equal "mixed-scenario", modern_post.slug

    # Both should be valid due to different blog_id values
    assert legacy_post.valid?
    assert modern_post.valid?
  end
end
