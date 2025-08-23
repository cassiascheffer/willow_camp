# ABOUTME: Comprehensive test suite for Blog model
# ABOUTME: Tests associations, validations, callbacks, scopes and methods
require "test_helper"

class BlogTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)

    @blog = Blog.new(
      user: @user,
      subdomain: "testblog",
      title: "Test Blog",
      slug: "test-blog",
      meta_description: "A test blog",
      favicon_emoji: "🚀",
      theme: "light",
      no_index: false
    )
  end

  # Association Tests
  test "belongs to user" do
    assert_respond_to @blog, :user
    assert_equal @user, @blog.user
  end

  test "has many posts" do
    assert_respond_to @blog, :posts
    @blog.save!
    post = @blog.posts.create!(
      title: "Test Post",
      body_markdown: "Test content",
      author: @user
    )
    assert_includes @blog.posts, post
  end

  test "has many pages" do
    assert_respond_to @blog, :pages
    @blog.save!
    # Skip callback to avoid duplicate about page
    @blog.pages.create!(
      title: "Test Page",
      body_markdown: "Page content",
      author: @user
    )
    assert_equal 2, @blog.pages.count # Including auto-created About page
  end

  test "destroys associated posts when destroyed" do
    @blog.save!
    @blog.posts.create!(
      title: "Test Post",
      body_markdown: "Test content",
      author: @user
    )
    # Blog creates an About page automatically, so we have 2 posts total (1 post + 1 page)
    assert_difference "Post.count", -2 do
      @blog.destroy
    end
  end

  test "destroys associated pages when destroyed" do
    @blog.save!
    assert_difference "Page.count", -1 do # About page gets destroyed
      @blog.destroy
    end
  end

  # Validation Tests
  test "valid blog" do
    assert @blog.valid?
  end

  test "subdomain uniqueness" do
    @blog.save!
    duplicate_blog = Blog.new(
      user: @user,
      subdomain: "testblog",
      favicon_emoji: "🎯"
    )
    assert_not duplicate_blog.valid?
    assert_includes duplicate_blog.errors[:subdomain], "has already been taken"
  end

  test "subdomain format validation" do
    @blog.subdomain = "test-blog"
    assert_not @blog.valid?
    assert_includes @blog.errors[:subdomain], "may only contain letters and numbers"

    @blog.subdomain = "test_blog"
    assert_not @blog.valid?

    @blog.subdomain = "test123"
    assert @blog.valid?
  end

  test "subdomain length validation" do
    @blog.subdomain = "ab"
    assert_not @blog.valid?
    assert_includes @blog.errors[:subdomain].first, "too short"

    @blog.subdomain = "a" * 64
    assert_not @blog.valid?
    assert_includes @blog.errors[:subdomain].first, "too long"

    @blog.subdomain = "abc"
    assert @blog.valid?
  end

  test "subdomain reserved words exclusion" do
    %w[www api admin dashboard].each do |reserved|
      @blog.subdomain = reserved
      assert_not @blog.valid?
      assert_includes @blog.errors[:subdomain], "is reserved"
    end
  end

  test "subdomain can be blank" do
    @blog.subdomain = nil
    assert @blog.valid?
    @blog.subdomain = ""
    assert @blog.valid?
  end

  test "title length validation" do
    @blog.title = "a" * 256
    assert_not @blog.valid?
    assert_includes @blog.errors[:title].first, "too long"

    @blog.title = "a" * 255
    assert @blog.valid?
  end

  test "meta_description length validation" do
    @blog.meta_description = "a" * 256
    assert_not @blog.valid?
    assert_includes @blog.errors[:meta_description].first, "too long"

    @blog.meta_description = "a" * 255
    assert @blog.valid?
  end

  test "post_footer_markdown length validation" do
    @blog.post_footer_markdown = "a" * 10001
    assert_not @blog.valid?
    assert_includes @blog.errors[:post_footer_markdown].first, "too long"

    @blog.post_footer_markdown = "a" * 10000
    assert @blog.valid?
  end

  test "favicon_emoji presence validation" do
    # The validation has both presence: true and allow_blank: true
    # presence: true prevents nil, but allow_blank: true allows ""
    @blog.favicon_emoji = nil
    assert @blog.valid? # allow_blank: true allows nil
  end

  test "favicon_emoji blank string validation" do
    @blog.favicon_emoji = ""
    assert @blog.valid? # allow_blank: true allows empty string
  end

  test "favicon_emoji format validation" do
    @blog.favicon_emoji = "not emoji"
    assert_not @blog.valid?
    assert_includes @blog.errors[:favicon_emoji], "must be a single emoji"

    @blog.favicon_emoji = "🚀🎯"
    assert_not @blog.valid?
    assert_includes @blog.errors[:favicon_emoji], "must be a single emoji"

    @blog.favicon_emoji = "🚀"
    assert @blog.valid?
  end

  test "custom_domain uniqueness" do
    @blog.custom_domain = "example.com"
    @blog.save!

    duplicate_blog = Blog.new(
      user: @user,
      custom_domain: "example.com",
      favicon_emoji: "🎯"
    )
    assert_not duplicate_blog.valid?
    assert_includes duplicate_blog.errors[:custom_domain], "has already been taken"
  end

  test "custom_domain format validation" do
    @blog.custom_domain = "not..valid"
    assert_not @blog.valid?
    assert_includes @blog.errors[:custom_domain], "must be a valid domain name"

    @blog.custom_domain = "valid-domain.com"
    assert @blog.valid?
  end

  test "custom_domain can be blank" do
    @blog.custom_domain = nil
    assert @blog.valid?
    @blog.custom_domain = ""
    assert @blog.valid?
  end

  # Normalization Tests
  test "normalizes subdomain" do
    @blog.subdomain = "  TestBlog  "
    @blog.save!
    assert_equal "testblog", @blog.subdomain
  end

  test "normalizes custom_domain" do
    @blog.custom_domain = "  EXAMPLE.COM  "
    @blog.save!
    assert_equal "example.com", @blog.custom_domain
  end

  test "normalizes blank custom_domain to nil" do
    @blog.custom_domain = "  "
    @blog.save!
    assert_nil @blog.custom_domain
  end

  # Callback Tests
  test "sets post_footer_html from markdown before save" do
    @blog.post_footer_markdown = "**Bold footer**"
    @blog.save!
    assert_match(/<strong>Bold footer<\/strong>/, @blog.post_footer_html)
  end

  test "clears post_footer_html when markdown is blank" do
    @blog.post_footer_markdown = "**Bold footer**"
    @blog.save!
    assert_not_nil @blog.post_footer_html

    @blog.post_footer_markdown = ""
    @blog.save!
    assert_nil @blog.post_footer_html
  end

  test "creates about page after create" do
    assert_difference "Page.count", 1 do
      @blog.save!
    end

    about_page = @blog.pages.find_by(slug: "about")
    assert_not_nil about_page
    assert_equal "About", about_page.title
  end

  test "creates about page through callback after create" do
    # This test verifies the normal behavior
    assert_difference "Page.count", 1 do
      @blog.save!
    end
    about_page = @blog.pages.find_by(slug: "about")
    assert_not_nil about_page
  end

  test "migration can bypass about page creation using insert" do
    # This simulates what the migration does to avoid duplicate About pages
    assert_difference "Page.count", 0 do
      Blog.insert(@blog.attributes.merge(
        "id" => SecureRandom.uuid,
        "created_at" => Time.current,
        "updated_at" => Time.current
      ))
    end
  end

  # Scope Tests
  test "by_domain scope with subdomain" do
    @blog.subdomain = "testblog"
    @blog.save!

    found = Blog.by_domain("testblog.willow.camp").first
    assert_equal @blog, found

    found = Blog.by_domain("testblog.localhost").first if Rails.env.local?
    assert_equal @blog, found if Rails.env.local?
  end

  test "by_domain scope with custom domain" do
    @blog.custom_domain = "example.com"
    @blog.save!

    found = Blog.by_domain("example.com").first
    assert_equal @blog, found
  end

  test "by_domain scope strips port" do
    @blog.custom_domain = "example.com"
    @blog.save!

    found = Blog.by_domain("example.com:3000").first
    assert_equal @blog, found
  end

  test "by_domain scope returns none for blank domain" do
    assert_empty Blog.by_domain("")
    assert_empty Blog.by_domain(nil)
  end

  # Method Tests
  test "domain returns custom_domain when present" do
    @blog.custom_domain = "example.com"
    @blog.subdomain = "testblog"
    assert_equal "example.com", @blog.domain
  end

  test "domain returns subdomain.willow.camp when no custom_domain" do
    @blog.custom_domain = nil
    @blog.subdomain = "testblog"
    assert_equal "testblog.willow.camp", @blog.domain
  end

  test "domain returns nil when neither custom_domain nor subdomain present" do
    @blog.custom_domain = nil
    @blog.subdomain = nil
    assert_nil @blog.domain
  end

  test "uses_custom_domain?" do
    @blog.custom_domain = nil
    assert_not @blog.uses_custom_domain?

    @blog.custom_domain = "example.com"
    assert @blog.uses_custom_domain?
  end

  test "social_share_image_enabled? in test environment" do
    assert @blog.social_share_image_enabled?
  end

  test "should_redirect_to_custom_domain?" do
    @blog.custom_domain = nil
    assert_not @blog.should_redirect_to_custom_domain?("any.host")

    @blog.custom_domain = "example.com"
    assert @blog.should_redirect_to_custom_domain?("other.host")
    assert_not @blog.should_redirect_to_custom_domain?("example.com")
  end

  # Tag Helper Method Tests
  test "all_tags returns tags from blog posts" do
    @blog.save!
    @blog.posts.create!(
      title: "Post 1",
      body_markdown: "Content",
      author: @user,
      tag_list: ["ruby", "rails"]
    )
    @blog.posts.create!(
      title: "Post 2",
      body_markdown: "Content",
      author: @user,
      tag_list: ["ruby", "testing"]
    )

    tags = @blog.all_tags.pluck(:name)
    assert_equal ["rails", "ruby", "testing"], tags.sort
  end

  test "tags_with_counts returns tags with usage counts for published posts" do
    @blog.save!
    @blog.posts.create!(
      title: "Post 1",
      body_markdown: "Content",
      author: @user,
      published: true,
      tag_list: ["ruby", "rails"]
    )
    @blog.posts.create!(
      title: "Post 2",
      body_markdown: "Content",
      author: @user,
      published: false,
      tag_list: ["ruby", "testing"]
    )

    tags = @blog.tags_with_counts
    ruby_tag = tags.find { |t| t.name == "ruby" }
    assert_equal 1, ruby_tag.taggings_count # Only counts published post

    testing_tag = tags.find { |t| t.name == "testing" }
    assert_nil testing_tag # Not in published posts
  end

  test "all_tags_with_counts returns tags with usage counts for all posts" do
    @blog.save!
    @blog.posts.create!(
      title: "Post 1",
      body_markdown: "Content",
      author: @user,
      published: true,
      tag_list: ["ruby", "rails"]
    )
    @blog.posts.create!(
      title: "Post 2",
      body_markdown: "Content",
      author: @user,
      published: false,
      tag_list: ["ruby", "testing"]
    )

    tags = @blog.all_tags_with_counts
    ruby_tag = tags.find { |t| t.name == "ruby" }
    assert_equal 2, ruby_tag.taggings_count # Counts both posts
  end

  test "all_tags_with_published_and_draft_counts returns separate counts" do
    @blog.save!
    @blog.posts.create!(
      title: "Post 1",
      body_markdown: "Content",
      author: @user,
      published: true,
      tag_list: ["ruby", "rails"]
    )
    @blog.posts.create!(
      title: "Post 2",
      body_markdown: "Content",
      author: @user,
      published: false,
      tag_list: ["ruby", "testing"]
    )

    tags = @blog.all_tags_with_published_and_draft_counts
    ruby_tag = tags.find { |t| t.name == "ruby" }
    assert_equal 1, ruby_tag.published_count
    assert_equal 1, ruby_tag.draft_count
    assert_equal 2, ruby_tag.taggings_count
  end
end
