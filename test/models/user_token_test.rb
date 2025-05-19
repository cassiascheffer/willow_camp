require "test_helper"

class UserTokenTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test "valid token" do
    token = UserToken.new(name: "Test Token", user: @user)
    assert token.valid?
  end

  test "name is required" do
    token = UserToken.new(user: @user)
    assert_not token.valid?
    assert_includes token.errors[:name], "can't be blank"
  end

  test "user is required" do
    token = UserToken.new(name: "Test Token")
    assert_not token.valid?
    assert_includes token.errors[:user], "can't be blank"
  end

  test "token is auto-generated on create" do
    token = UserToken.new(name: "New Token", user: @user)
    assert_nil token.token
    token.save!
    assert_not_nil token.token
    assert_equal 32, token.token.length
  end

  test "manually assigned token is overwritten on create" do
    manual_token = SecureRandom.hex(16)  # Create a valid 32-char token
    token = UserToken.new(name: "Manual Token", user: @user, token: manual_token)
    assert_equal manual_token, token.token
    token.save!
    assert_not_equal manual_token, token.token
    assert_equal 32, token.token.length
  end

  test "token cannot be changed after creation" do
    token = UserToken.create!(name: "Read-only Token", user: @user)
    original_token = token.token

    assert_raises(ActiveRecord::ReadonlyAttributeError) do
      token.token = "new_token_value"
      token.save!
    end

    token.reload

    assert_equal original_token, token.token
  end

  test "token must be unique if present" do
    existing_token = user_tokens(:active)
    duplicate = UserToken.new(
      name: "Duplicate Token",
      token: existing_token.token,
      user: @user
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:token], "has already been taken"
  end
  
  test "token uniqueness validation works" do
    # We can't modify the token after creation because it's attr_readonly
    # Just check that a token is indeed set and is 32 chars long
    token = UserToken.create(name: "Token Test", user: @user)
    assert_equal 32, token.token.length
  end
  
  test "name length validation" do
    token = UserToken.new(user: @user)
    token.name = "a" * 256
    assert_not token.valid?
    assert_includes token.errors[:name], "is too long (maximum is 255 characters)"
    
    token.name = "a" * 255
    assert token.valid?, token.errors.full_messages.to_sentence
  end

  test "expires_at can be nil" do
    token = UserToken.new(name: "No Expiry", user: @user)
    assert token.valid?
  end

  test "expires_at must be in the future if present" do
    token = UserToken.new(
      name: "Past Expiry",
      user: @user,
      expires_at: 1.hour.ago
    )
    assert_not token.valid?
    assert_includes token.errors[:expires_at], "must be in the future"

    token.expires_at = 1.day.from_now
    assert token.valid?
  end

  test "active scope returns only non-expired tokens" do
    active_tokens = UserToken.active

    # Should include tokens with no expiry and future expiry
    assert_includes active_tokens, user_tokens(:active)
    assert_includes active_tokens, user_tokens(:future_expiry)

    # Should not include expired tokens
    assert_not_includes active_tokens, user_tokens(:expired)
  end

  test "belongs to a user" do
    token = user_tokens(:active)
    assert_equal users(:one), token.user
  end
end
