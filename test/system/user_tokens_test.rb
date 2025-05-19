require "application_system_test_case"

class UserTokensTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    # Sign in as the user
    visit new_session_path
    fill_in "Enter your email address", with: @user.email_address
    fill_in "Enter your password", with: "password"
    click_on "Sign in"

    # Navigate to the dashboard settings page where tokens are managed
    visit dashboard_settings_path
  end

  test "viewing tokens" do
    assert_selector "h2", text: "API Tokens"
    assert_selector "div", id: "tokens-list"
  end

  test "creating a new token" do
    token_name = "Test Token #{Time.current.to_i}"

    # Open the new token form if it's not already visible
    if has_selector?("a", text: "Create new token")
      click_on "Create new token"
    end

    fill_in "Name", with: token_name
    click_on "Create Token"

    assert_text "Token created successfully"
    assert_text token_name
  end

  test "creating a token with expiration date" do
    token_name = "Expiring Token #{Time.current.to_i}"

    # Open the new token form if it's not already visible
    if has_selector?("a", text: "Create new token")
      click_on "Create new token"
    end

    fill_in "Name", with: token_name
    # Set expiration date to 1 month from now
    expiry_date = 1.month.from_now.to_date
    fill_in "Expires at", with: expiry_date
    click_on "Create Token"

    assert_text "Token created successfully"
    assert_text token_name
    assert_text expiry_date.strftime("%b %-d, %Y") # Format may vary based on your app
  end

  test "cannot create token with blank name" do
    # Open the new token form if it's not already visible
    if has_selector?("a", text: "Create new token")
      click_on "Create new token"
    end

    fill_in "Name", with: ""
    click_on "Create Token"

    assert_text "Failed to create token" # or however your app shows validation errors
  end

  test "cannot create token with past expiration date" do
    token_name = "Invalid Token #{Time.current.to_i}"

    # Open the new token form if it's not already visible
    if has_selector?("a", text: "Create new token")
      click_on "Create new token"
    end

    fill_in "Name", with: token_name
    # Set expiration date to yesterday
    fill_in "Expires at", with: 1.day.ago.to_date
    click_on "Create Token"

    assert_text "Failed to create token" # or however your app shows validation errors
  end

  test "deleting a token" do
    # Assuming there's at least one token present
    # Find a token and click its delete button
    within "#tokens-list" do
      if has_button?("Delete")
        accept_confirm do
          click_on "Delete", match: :first
        end
        assert_text "Token deleted successfully"
      else
        # Create a token if none exists
        token_name = "Delete Test Token #{Time.current.to_i}"

        # Open the new token form if it's not already visible
        if has_selector?("a", text: "Create new token")
          click_on "Create new token"
        end

        fill_in "Name", with: token_name
        click_on "Create Token"

        # Now delete the newly created token
        accept_confirm do
          click_on "Delete", match: :first
        end
        assert_text "Token deleted successfully"
      end
    end
  end

  test "token is displayed after creation" do
    token_name = "Display Test Token #{Time.current.to_i}"

    # Open the new token form if it's not already visible
    if has_selector?("a", text: "Create new token")
      click_on "Create new token"
    end

    fill_in "Name", with: token_name
    click_on "Create Token"

    assert_text "Token created successfully"

    # Check if the token value is displayed to the user after creation
    # This assumes your app shows the token value once after creation
    assert_selector "div", class: "token-value"
  end
end
