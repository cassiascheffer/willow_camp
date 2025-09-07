require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  def setup
    @blog_with_subdomain = blogs(:one)
    @blog_with_custom_domain = blogs(:custom_domain_blog)
    @blog_without_title = blogs(:no_title_blog)
    @blog_with_custom_domain_no_title = Blog.create!(
      user: users(:custom_domain_no_title),
      subdomain: "customnotitle",
      custom_domain: "example.org",
      primary: true
    )
  end

  test "blog_title_for returns willow.camp for nil blog" do
    assert_equal "willow.camp", blog_title_for(nil)
  end

  test "blog_title_for returns willow.camp when blog has no subdomain or custom domain" do
    blog = Blog.new(subdomain: nil, custom_domain: nil)
    assert_equal "willow.camp", blog_title_for(blog)
  end

  test "blog_title_for returns willow.camp when blog has blank subdomain and custom domain" do
    blog = Blog.new(subdomain: "", custom_domain: "")
    assert_equal "willow.camp", blog_title_for(blog)
  end

  test "blog_title_for returns blog title when present for subdomain blog" do
    assert_equal "One's Blog", blog_title_for(@blog_with_subdomain)
  end

  test "blog_title_for returns blog title when present for custom domain blog" do
    assert_equal "My Custom Blog", blog_title_for(@blog_with_custom_domain)
  end

  test "blog_title_for returns subdomain domain when no blog title" do
    assert_equal "notitle.willow.camp", blog_title_for(@blog_without_title)
  end

  test "blog_title_for returns custom domain when no blog title" do
    assert_equal "example.org", blog_title_for(@blog_with_custom_domain_no_title)
  end

  test "blog_title_for prefers blog title over domain" do
    # Blog has both title and custom domain
    assert_equal "My Custom Blog", blog_title_for(@blog_with_custom_domain)
    assert_not_equal "myblog.com", blog_title_for(@blog_with_custom_domain)
  end

  test "blog_title_for handles blog with blank title" do
    @blog_with_subdomain.title = ""
    assert_equal "one.willow.camp", blog_title_for(@blog_with_subdomain)

    @blog_with_custom_domain.title = ""
    assert_equal "myblog.com", blog_title_for(@blog_with_custom_domain)
  end

  test "blog_title_for handles blog with whitespace-only title" do
    @blog_with_subdomain.title = "   "
    assert_equal "one.willow.camp", blog_title_for(@blog_with_subdomain)

    @blog_with_custom_domain.title = "   "
    assert_equal "myblog.com", blog_title_for(@blog_with_custom_domain)
  end

  test "blog_title_for handles blog with nil title" do
    @blog_with_subdomain.title = nil
    assert_equal "one.willow.camp", blog_title_for(@blog_with_subdomain)

    @blog_with_custom_domain.title = nil
    assert_equal "myblog.com", blog_title_for(@blog_with_custom_domain)
  end

  test "blog_title_for prioritizes custom domain over subdomain" do
    blog = Blog.new(
      subdomain: "test",
      custom_domain: "example.com",
      title: nil
    )
    assert_equal "example.com", blog_title_for(blog)
  end

  test "blog_title_for handles edge cases" do
    blog_subdomain_only = Blog.new(subdomain: "test", custom_domain: nil, title: nil)
    assert_equal "test.willow.camp", blog_title_for(blog_subdomain_only)

    blog_custom_only = Blog.new(subdomain: nil, custom_domain: "test.com", title: nil)
    assert_equal "test.com", blog_title_for(blog_custom_only)

    blog_neither = Blog.new(subdomain: nil, custom_domain: nil, title: nil)
    assert_equal "willow.camp", blog_title_for(blog_neither)
  end

  test "blog_title_for works with real blog objects" do
    assert_equal "One's Blog", blog_title_for(@blog_with_subdomain)
    assert_equal "My Custom Blog", blog_title_for(@blog_with_custom_domain)
    assert_equal "notitle.willow.camp", blog_title_for(@blog_without_title)
    assert_equal "example.org", blog_title_for(@blog_with_custom_domain_no_title)
  end

  test "url_options_for helper returns correct options for subdomain blogs" do
    assert_equal({subdomain: @blog_with_subdomain.subdomain}, url_options_for(@blog_with_subdomain))
  end

  test "url_options_for helper returns correct options for custom domain blogs" do
    assert_equal({host: @blog_with_custom_domain.custom_domain}, url_options_for(@blog_with_custom_domain))
  end

  test "url_options_for helper returns empty hash for nil blog" do
    assert_equal({}, url_options_for(nil))
  end

  test "url_options_for helper returns empty hash for blog with no subdomain or custom domain" do
    blog = Blog.new(subdomain: nil, custom_domain: nil)
    assert_equal({}, url_options_for(blog))
  end

  test "url_options_for helper returns empty hash for blog with blank subdomain and no custom domain" do
    blog = Blog.new(subdomain: "", custom_domain: nil)
    assert_equal({}, url_options_for(blog))
  end

  test "url_options_for helper prioritizes custom domain over subdomain" do
    blog = Blog.new(subdomain: "test", custom_domain: "example.com")
    assert_equal({host: "example.com"}, url_options_for(blog))
  end
end
