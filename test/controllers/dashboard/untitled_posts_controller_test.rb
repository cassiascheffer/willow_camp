require "test_helper"

class Dashboard::UntitledPostsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    @blog = @user.blogs.first || @user.blogs.create!(
      subdomain: "testblog#{@user.id[0..7]}",
      favicon_emoji: "📝"
    )
    sign_in @user
  end

  test "should create untitled post and redirect to edit" do
    assert_difference("Post.count") do
      post dashboard_untitled_posts_url(blog_subdomain: @blog.subdomain)
    end

    created_post = @blog.posts.order(:created_at).last
    assert_equal "Untitled", created_post.title
    assert_equal "untitled", created_post.slug
    assert_equal false, created_post.published
    assert_equal @user, created_post.author
    assert_equal @blog, created_post.blog

    assert_redirected_to edit_dashboard_post_path(blog_subdomain: @blog.subdomain, id: created_post.id)
  end

  test "should require authentication" do
    sign_out @user
    post dashboard_untitled_posts_url(blog_subdomain: @blog.subdomain)
    assert_redirected_to new_user_session_path
  end
end
