require "test_helper"

class RobotsControllerTest < ActionDispatch::IntegrationTest
  test "should get robots.txt" do
    get "/robots.txt"
    assert_response :success
    assert_equal "text/plain", response.media_type
  end

  test "should set proper cache headers" do
    get "/robots.txt"
    assert_response :success
    assert_not_nil response.headers["Cache-Control"]
    assert_includes response.headers["Cache-Control"], "public"
    assert_includes response.headers["Cache-Control"], "max-age"
  end

  test "should contain expected directives" do
    get "/robots.txt"
    assert_response :success

    body = response.body
    assert_includes body, "User-agent: *"
    assert_includes body, "Allow: /"
    assert_includes body, "Disallow: /dashboard"
    assert_includes body, "Disallow: /api/"
    assert_includes body, "Crawl-delay: 1"
  end

  test "should disallow authentication pages" do
    get "/robots.txt"
    assert_response :success

    body = response.body
    assert_includes body, "Disallow: /users/login"
    assert_includes body, "Disallow: /users/logout"
    assert_includes body, "Disallow: /users/signup"
    assert_includes body, "Disallow: /users/register"
  end

  test "should disallow admin and system areas" do
    get "/robots.txt"
    assert_response :success

    body = response.body
    assert_includes body, "Disallow: /dashboard/"
    assert_includes body, "Disallow: /up"
    assert_includes body, "Disallow: /rails/"
  end
end
