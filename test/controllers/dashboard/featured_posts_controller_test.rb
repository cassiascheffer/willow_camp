require "test_helper"

class Dashboard::FeaturedPostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @blog = blogs(:one)
    @post = posts(:one)
    @post.update!(author: @user, blog: @blog)
    sign_in @user
  end

  test "should update post to featured" do
    @post.update!(featured: false)

    patch dashboard_featured_post_path(blog_subdomain: @blog.subdomain, id: @post.id), params: {featured: "true"}

    assert_response :no_content
    assert @post.reload.featured?
  end

  test "should update post to not featured" do
    @post.update!(featured: true)

    patch dashboard_featured_post_path(blog_subdomain: @blog.subdomain, id: @post.id), params: {featured: "false"}

    assert_response :no_content
    assert_not @post.reload.featured?
  end

  test "should require authentication" do
    sign_out @user

    patch dashboard_featured_post_path(blog_subdomain: @blog.subdomain, id: @post.id), params: {featured: "true"}

    assert_redirected_to new_user_session_path
  end
end
