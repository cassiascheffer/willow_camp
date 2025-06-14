require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  def setup
    @user_with_subdomain = users(:one)
    @user_with_custom_domain = users(:custom_domain_user)
    @user_without_blog_title = users(:no_blog_title)
    @user_with_custom_domain_no_title = users(:custom_domain_no_title)
  end

  test "blog_title_for returns willow.camp for nil author" do
    assert_equal "willow.camp", blog_title_for(nil)
  end

  test "blog_title_for returns willow.camp when author has no subdomain or custom domain" do
    user = User.new(subdomain: nil, custom_domain: nil)
    assert_equal "willow.camp", blog_title_for(user)
  end

  test "blog_title_for returns willow.camp when author has blank subdomain and custom domain" do
    user = User.new(subdomain: "", custom_domain: "")
    assert_equal "willow.camp", blog_title_for(user)
  end

  test "blog_title_for returns blog_title when present for subdomain user" do
    assert_equal "One's Blog", blog_title_for(@user_with_subdomain)
  end

  test "blog_title_for returns blog_title when present for custom domain user" do
    assert_equal "My Custom Blog", blog_title_for(@user_with_custom_domain)
  end

  test "blog_title_for returns subdomain domain when no blog_title" do
    assert_equal "notitle.willow.camp", blog_title_for(@user_without_blog_title)
  end

  test "blog_title_for returns custom domain when no blog_title" do
    assert_equal "example.org", blog_title_for(@user_with_custom_domain_no_title)
  end

  test "blog_title_for prefers blog_title over domain" do
    # User has both blog_title and custom domain
    assert_equal "My Custom Blog", blog_title_for(@user_with_custom_domain)
    assert_not_equal "myblog.com", blog_title_for(@user_with_custom_domain)
  end

  test "blog_title_for handles user with blank blog_title" do
    @user_with_subdomain.blog_title = ""
    assert_equal "one.willow.camp", blog_title_for(@user_with_subdomain)

    @user_with_custom_domain.blog_title = ""
    assert_equal "myblog.com", blog_title_for(@user_with_custom_domain)
  end

  test "blog_title_for handles user with whitespace-only blog_title" do
    @user_with_subdomain.blog_title = "   "
    assert_equal "one.willow.camp", blog_title_for(@user_with_subdomain)

    @user_with_custom_domain.blog_title = "   "
    assert_equal "myblog.com", blog_title_for(@user_with_custom_domain)
  end

  test "blog_title_for handles user with nil blog_title" do
    @user_with_subdomain.blog_title = nil
    assert_equal "one.willow.camp", blog_title_for(@user_with_subdomain)

    @user_with_custom_domain.blog_title = nil
    assert_equal "myblog.com", blog_title_for(@user_with_custom_domain)
  end

  test "blog_title_for prioritizes custom domain over subdomain" do
    # User has both custom domain and subdomain, but no blog title
    user = User.new(
      subdomain: "testuser",
      custom_domain: "example.com",
      blog_title: nil
    )
    assert_equal "example.com", blog_title_for(user)
  end

  test "blog_title_for handles edge cases" do
    # User with only subdomain, no custom domain
    user_subdomain_only = User.new(subdomain: "test", custom_domain: nil)
    assert_equal "test.willow.camp", blog_title_for(user_subdomain_only)

    # User with only custom domain, no subdomain
    user_custom_only = User.new(subdomain: nil, custom_domain: "test.com")
    assert_equal "test.com", blog_title_for(user_custom_only)

    # User with neither
    user_neither = User.new(subdomain: nil, custom_domain: nil)
    assert_equal "willow.camp", blog_title_for(user_neither)
  end

  test "blog_title_for works with real user objects" do
    # Test with actual saved users to ensure it works with database objects
    assert_equal "One's Blog", blog_title_for(@user_with_subdomain)
    assert_equal "My Custom Blog", blog_title_for(@user_with_custom_domain)
    assert_equal "notitle.willow.camp", blog_title_for(@user_without_blog_title)
    assert_equal "example.org", blog_title_for(@user_with_custom_domain_no_title)
  end
end
