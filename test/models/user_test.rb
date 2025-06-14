require "test_helper"

class UserTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @custom_domain_user = users(:custom_domain_user)
    @no_blog_title_user = users(:no_blog_title)
    @custom_domain_no_title_user = users(:custom_domain_no_title)
  end

  test "should be valid" do
    assert @user.valid?
  end

  test "email should be present" do
    @user.email = "    "
    assert_not @user.valid?
  end

  test "email should be unique" do
    duplicate_user = @user.dup
    @user.save
    assert_not duplicate_user.valid?
  end

  test "subdomain should allow blank" do
    @user.subdomain = "   "
    assert @user.valid?
  end

  test "subdomain should be unique" do
    duplicate_user = @user.dup
    duplicate_user.email = "another@example.com"
    @user.save
    assert_not duplicate_user.valid?
  end

  test "subdomain should be valid format" do
    valid_subdomains = %w[myuser test-blog my_blog 123 a-b-c]
    valid_subdomains.each do |valid_subdomain|
      @user.subdomain = valid_subdomain
      assert @user.valid?, "#{valid_subdomain} should be valid"
    end

    invalid_subdomains = %w[user! test@blog my.blog space\ here <script>]
    invalid_subdomains.each do |invalid_subdomain|
      @user.subdomain = invalid_subdomain
      assert_not @user.valid?, "#{invalid_subdomain} should be invalid"
    end
  end

  test "subdomain should have minimum length" do
    @user.subdomain = "ab"
    assert_not @user.valid?
    @user.subdomain = "abc"
    assert @user.valid?
  end

  test "subdomain should be normalized" do
    mixed_case_subdomain = "TestSubDomain"
    @user.subdomain = mixed_case_subdomain
    @user.save
    assert_equal mixed_case_subdomain.strip.downcase, @user.reload.subdomain
  end

  test "password should be present" do
    @user.password = @user.password_confirmation = " " * 6
    assert_not @user.valid?
  end

  test "password should have a minimum length" do
    @user.password = @user.password_confirmation = "a" * 5
    assert_not @user.valid?
  end

  test "email should be normalized" do
    mixed_case_email = "User@ExAMPle.CoM"
    @user.email = mixed_case_email
    @user.save
    assert_equal mixed_case_email.strip.downcase, @user.reload.email
  end

  test "should destroy associated posts when user is destroyed" do
    user = User.create!(
      name: "Test User",
      email: "test_destroy@example.com",
      password: "password123",
      password_confirmation: "password123",
      subdomain: "testdestroy"
    )
    user.posts.create!(title: "Test Post", body_markdown: "Lorem ipsum")

    assert_difference "Post.count", -1 do
      user.destroy
    end
  end

  test "should destroy associated tokens when user is destroyed" do
    user = User.create!(
      name: "Test User",
      email: "test_tokens@example.com",
      password: "password123",
      password_confirmation: "password123",
      subdomain: "testtokens"
    )
    user.tokens.create!(name: "API Token")

    assert_difference "UserToken.count", -1 do
      user.destroy
    end
  end

  # Custom domain tests
  test "custom domain should allow blank" do
    @user.custom_domain = "   "
    assert @user.valid?
  end

  test "custom domain should be unique" do
    duplicate_user = User.new(
      name: "Another User",
      email: "another@example.com",
      password: "password123",
      password_confirmation: "password123",
      subdomain: "anotheruser",
      custom_domain: @custom_domain_user.custom_domain
    )
    assert_not duplicate_user.valid?
  end

  test "custom domain should be valid format" do
    valid_domains = %w[example.com blog.example.com my-site.org test123.net]
    valid_domains.each do |valid_domain|
      @user.custom_domain = valid_domain
      assert @user.valid?, "#{valid_domain} should be valid"
    end

    invalid_domains = %w[invalid localhost example .com example. example..com example.c]
    invalid_domains.each do |invalid_domain|
      @user.custom_domain = invalid_domain
      assert_not @user.valid?, "#{invalid_domain} should be invalid"
    end
  end

  test "custom domain should be normalized" do
    mixed_case_domain = "ExAmPlE.CoM"
    @user.custom_domain = mixed_case_domain
    @user.save
    assert_equal mixed_case_domain.strip.downcase, @user.reload.custom_domain
  end

  test "domain method returns custom domain when present" do
    assert_equal "myblog.com", @custom_domain_user.domain
  end

  test "domain method returns subdomain when custom domain blank" do
    assert_equal "one.willow.camp", @user.domain
  end

  test "domain method returns nil when both domains blank" do
    user = User.new(subdomain: nil, custom_domain: nil)
    assert_nil user.domain
  end

  test "uses_custom_domain? returns true when custom domain present" do
    assert @custom_domain_user.uses_custom_domain?
  end

  test "uses_custom_domain? returns false when custom domain blank" do
    assert_not @user.uses_custom_domain?
  end

  test "should_redirect_to_custom_domain? returns true when custom domain differs from current host" do
    assert @custom_domain_user.should_redirect_to_custom_domain?("customuser.willow.camp")
  end

  test "should_redirect_to_custom_domain? returns false when current host matches custom domain" do
    assert_not @custom_domain_user.should_redirect_to_custom_domain?("myblog.com")
  end

  test "should_redirect_to_custom_domain? returns false when no custom domain" do
    assert_not @user.should_redirect_to_custom_domain?("one.willow.camp")
  end

  test "find_by_domain finds user by custom domain" do
    found_user = User.find_by_domain("myblog.com")
    assert_equal @custom_domain_user, found_user
  end

  test "find_by_domain finds user by subdomain" do
    found_user = User.find_by_domain("one.willow.camp")
    assert_equal @user, found_user
  end

  test "find_by_domain returns nil for non-existent domain" do
    found_user = User.find_by_domain("nonexistent.com")
    assert_nil found_user
  end

  test "find_by_domain returns nil for non-willow.camp domain without custom domain" do
    found_user = User.find_by_domain("random.com")
    assert_nil found_user
  end

  test "find_by_domain prioritizes custom domain over subdomain" do
    # When searching for custom domain, should find the user with custom domain
    found_user = User.find_by_domain("myblog.com")
    assert_equal @custom_domain_user, found_user
  end
end
