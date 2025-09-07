require "test_helper"

class UserTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
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
      password_confirmation: "password123"
    )
    user.posts.create!(title: "Test Post", body_markdown: "Lorem ipsum")

    assert_difference "Post.count", -1 do
      user.destroy
    end
  end

  # Blog Association Tests
  test "should have many blogs" do
    assert_respond_to @user, :blogs
  end

  test "should create and associate blogs" do
    blog = @user.blogs.create!(
      subdomain: "myblog",
      title: "My Blog",
      favicon_emoji: "🚀"
    )
    assert_includes @user.blogs, blog
    assert_equal @user, blog.user
  end

  test "should destroy associated blogs when user is destroyed" do
    user = User.create!(
      name: "Test User",
      email: "test_blogs@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    user.blogs.create!(
      subdomain: "testblogdestroy",
      favicon_emoji: "🎯"
    )

    assert_difference "Blog.count", -1 do
      user.destroy
    end
  end

  test "can have multiple blogs" do
    user = users(:test_user_no_blog)
    initial_count = user.blogs.count

    blog1 = user.blogs.create!(
      subdomain: "blog1",
      title: "First Blog",
      favicon_emoji: "🚀"
    )
    blog2 = user.blogs.create!(
      subdomain: "blog2",
      title: "Second Blog",
      favicon_emoji: "🎯"
    )

    assert_equal initial_count + 2, user.blogs.count
    assert_includes user.blogs, blog1
    assert_includes user.blogs, blog2
  end

  test "should destroy associated tokens when user is destroyed" do
    user = User.create!(
      name: "Test User",
      email: "test_tokens@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    user.tokens.create!(name: "API Token")

    assert_difference "UserToken.count", -1 do
      user.destroy
    end
  end
end
