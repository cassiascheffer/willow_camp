require "test_helper"

class UserTest < ActiveSupport::TestCase
  def setup
    @user = User.new(
      email_address: "user@example.com",
      password: "password123",
      password_confirmation: "password123",
      subdomain: "testuser"
    )
  end

  test "should be valid" do
    assert @user.valid?
  end

  test "email_address should be present" do
    @user.email_address = "    "
    assert_not @user.valid?
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
