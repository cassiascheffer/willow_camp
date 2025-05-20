require "test_helper"

class PostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @post = posts(:one)
    @user = users(:one)
    host = "#{@user.subdomain}.example.com"
    @headers = {host: host}
  end

  test "should get index" do
    get posts_url, headers: @headers
    assert_response :success
  end

  test "should show post" do
    get "/#{@post.slug}", headers: @headers
    assert_response :success
  end
end
