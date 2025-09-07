# ABOUTME: Test suite for Page model (STI from Post)
# ABOUTME: Tests Page-specific behavior and blog association
require "test_helper"

class PageTest < ActiveSupport::TestCase
  def setup
    @user = users(:test_user_no_blog)
    @blog = Blog.create!(
      user: @user,
      subdomain: "testblog#{SecureRandom.hex(4)}",
      favicon_emoji: "🚀"
    )
    @page = Page.new(
      blog: @blog,
      title: "About",
      body_markdown: "About page content"
    )
  end

  test "should inherit from Post" do
    assert_kind_of Post, @page
    assert_equal "Page", @page.type
  end

  test "should be valid with required attributes" do
    assert @page.valid?
  end

  test "should belong to author" do
    assert_respond_to @page, :author
    # Author is set automatically from blog during validation
    @page.valid?
    assert_equal @user, @page.author
  end

  test "should inherit blog association from Post" do
    assert_respond_to @page, :blog
    # Blog is optional for backwards compatibility
    assert @page.valid?
  end

  test "should be associated with blog when created through blog" do
    blog = Blog.create!(
      user: @user,
      subdomain: "anotherblog#{SecureRandom.hex(4)}",
      favicon_emoji: "🚀"
    )

    page = blog.pages.create!(
      title: "Custom Page",
      body_markdown: "Custom content"
    )

    assert_equal blog, page.blog
    assert_includes blog.pages, page
  end

  test "blog automatically creates about page on creation" do
    user = users(:custom_domain_no_title)
    blog = Blog.create!(
      user: user,
      subdomain: "autoblog",
      favicon_emoji: "🎯"
    )

    about_page = blog.pages.find_by(slug: "about")
    assert_not_nil about_page
    assert_equal "About", about_page.title
    assert_equal blog, about_page.blog
  end

  test "should use blog scope for friendly_id like posts" do
    user = users(:custom_domain_no_title)
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

    # Pages with same title in different blogs should have same slug
    page1 = blog1.pages.create!(
      title: "Contact",
      body_markdown: "Contact page 1",
      author: @user
    )
    page2 = blog2.pages.create!(
      title: "Contact",
      body_markdown: "Contact page 2",
      author: @user
    )

    assert_equal "contact", page1.slug
    assert_equal "contact", page2.slug
    assert_not_equal page1.id, page2.id
    assert_equal blog1, page1.blog
    assert_equal blog2, page2.blog
  end

  test "should be destroyed when blog is destroyed" do
    blog = Blog.create!(
      user: @user,
      subdomain: "destroyblog",
      favicon_emoji: "💥"
    )

    # Blog creates an About page automatically
    assert_equal 1, blog.pages.count

    # Add another page
    blog.pages.create!(
      title: "Contact",
      body_markdown: "Contact info",
      author: @user
    )
    assert_equal 2, blog.pages.count

    # Destroying blog should destroy all pages
    assert_difference "Page.count", -2 do
      blog.destroy
    end
  end

  test "should save and retrieve content correctly" do
    blog = Blog.create!(
      user: @user,
      subdomain: "contentblog",
      favicon_emoji: "📝"
    )

    page = blog.pages.create!(
      title: "Privacy Policy",
      body_markdown: "# Privacy Policy\n\nWe respect your privacy.",
      author: @user
    )

    reloaded_page = Page.find(page.id)
    assert_equal "Privacy Policy", reloaded_page.title
    assert_equal "# Privacy Policy\n\nWe respect your privacy.", reloaded_page.body_markdown
    assert_match(/Privacy Policy/, reloaded_page.body_html)
    assert_match(/<h1/, reloaded_page.body_html)
  end

  test "should work with acts_as_taggable through blog tenant" do
    blog = Blog.create!(
      user: @user,
      subdomain: "tagblog",
      favicon_emoji: "🏷️"
    )

    page = blog.pages.create!(
      title: "Services",
      body_markdown: "Our services",
      author: @user,
      tag_list: ["business", "services"]
    )

    assert_equal ["business", "services"], page.tag_list.sort
  end
end
