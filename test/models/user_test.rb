require "test_helper"

class UserTest < ActiveSupport::TestCase
  def setup
    @user = User.new(
      name: "Test User",
      email_address: "user@example.com",
      password: "password123",
      password_confirmation: "password123",
      subdomain: "testuser",
      blog_title: "Test User's Blog"
    )
  end

  test "should be valid" do
    assert @user.valid?
  end

  test "email_address should be present" do
    @user.email_address = "    "
    assert_not @user.valid?
  end

  test "email_address should be valid format" do
    invalid_addresses = %w[user@example,com user_at_example.com user.name@example. user@example_domain.com user@example+domain.com]
    invalid_addresses.each do |invalid_address|
      @user.email_address = invalid_address
      assert_not @user.valid?, "#{invalid_address} should be invalid"
    end
  end

  test "email_address should be unique" do
    duplicate_user = @user.dup
    @user.save
    assert_not duplicate_user.valid?
  end

  test "subdomain should be present" do
    @user.subdomain = "   "
    assert_not @user.valid?
  end

  test "subdomain should be unique" do
    duplicate_user = @user.dup
    duplicate_user.email_address = "another@example.com"
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

  test "email_address should be normalized" do
    mixed_case_email = "User@ExAMPle.CoM"
    @user.email_address = mixed_case_email
    @user.save
    assert_equal mixed_case_email.strip.downcase, @user.reload.email_address
  end

  test "should destroy associated sessions when user is destroyed" do
    @user.save
    @user.sessions.create!
    assert_difference "Session.count", -1 do
      @user.destroy
    end
  end

  test "should destroy associated posts when user is destroyed" do
    @user.save
    @user.posts.create!(title: "Test Post", body_markdown: "Lorem ipsum")
    assert_difference "Post.count", -1 do
      @user.destroy
    end
  end

  test "should destroy associated tokens when user is destroyed" do
    @user.save
    @user.tokens.create!(name: "API Token")
    assert_difference "UserToken.count", -1 do
      @user.destroy
    end
  end
end
