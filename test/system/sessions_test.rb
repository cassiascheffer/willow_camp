require "application_system_test_case"

class SessionsTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
  end

  test "visiting the login page" do
    visit new_session_path
    assert_selector "h1", text: "Sign in"
  end

  test "signing in with valid credentials" do
    visit new_session_path
    fill_in "Enter your email address", with: @user.email_address
    fill_in "Enter your password", with: "password"
    click_on "Sign in"

    assert_current_path dashboard_path
  end

  test "cannot sign in with invalid email" do
    visit new_session_path
    fill_in "Enter your email address", with: "wrong@example.com"
    fill_in "Enter your password", with: "password"
    click_on "Sign in"

    assert_text "Try another email address or password"
    assert_current_path new_session_path
  end

  test "cannot sign in with invalid password" do
    visit new_session_path
    fill_in "Enter your email address", with: @user.email_address
    fill_in "Enter your password", with: "wrongpassword"
    click_on "Sign in"

    assert_text "Try another email address or password"
    assert_current_path new_session_path
  end

  test "signing out" do
    # First sign in
    visit new_session_path
    fill_in "Enter your email address", with: @user.email_address
    fill_in "Enter your password", with: "password"
    click_on "Sign in"

    click_on "Sign out"

    assert_current_path new_session_path
  end

  test "cannot access protected pages when not signed in" do
    # Ensure we're logged out
    visit new_session_path

    # Try to access a protected page
    visit dashboard_path

    # Should be redirected to login
    assert_current_path new_session_path
  end

  test "rate limiting prevents too many login attempts" do
    # This test simulates the rate limiting behavior
    # Try to login 11 times (above the 10 limit in 3 minutes)
    11.times do |i|
      visit new_session_path
      fill_in "Enter your email address", with: "test#{i}@example.com"
      fill_in "Enter your password", with: "wrongpassword"
      click_on "Sign in"
    end

    # After too many attempts, should see rate limit message
    assert_text "Try again later"
  end
end
