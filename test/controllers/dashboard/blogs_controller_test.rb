require "test_helper"

class Dashboard::BlogsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    @blog = blogs(:one)
  end

  test "should redirect to session/new when not logged in" do
    get dashboard_blog_settings_path(blog_subdomain: @blog.subdomain)
    assert_redirected_to new_user_session_path
  end

  test "should get blog settings page when logged in" do
    sign_in(@user)
    get dashboard_blog_settings_path(blog_subdomain: @blog.subdomain)
    assert_response :success
    assert_not_nil assigns(:blog)
    assert_not_nil assigns(:about_page)
    assert_equal @blog, assigns(:blog)
    assert_nil assigns(:tokens)
    assert_nil assigns(:token)
  end

  test "should update blog with custom domain" do
    sign_in(@user)
    patch dashboard_blog_settings_path(blog_subdomain: @blog.subdomain), params: {
      blog: {
        title: "Updated Blog",
        custom_domain: "newdomain.com"
      }
    }
    assert_redirected_to dashboard_blog_settings_path(@blog.subdomain)
    @blog.reload
    assert_equal "Updated Blog", @blog.title
    assert_equal "newdomain.com", @blog.custom_domain
  end

  test "should update blog with blank custom domain" do
    sign_in(@user)
    @blog.update!(custom_domain: "olddomain.com")

    patch dashboard_blog_settings_path(blog_subdomain: @blog.subdomain), params: {
      blog: {
        custom_domain: ""
      }
    }
    assert_redirected_to dashboard_blog_settings_path(@blog.subdomain)
    @blog.reload
    assert_nil @blog.custom_domain
  end

  test "should update blog theme" do
    sign_in(@user)
    patch dashboard_blog_settings_path(blog_subdomain: @blog.subdomain), params: {
      blog: {
        theme: "dark"
      }
    }
    assert_redirected_to dashboard_blog_settings_path(@blog.subdomain)
    @blog.reload
    assert_equal "dark", @blog.theme
  end

  test "should update blog meta description" do
    sign_in(@user)
    patch dashboard_blog_settings_path(blog_subdomain: @blog.subdomain), params: {
      blog: {
        meta_description: "This is my awesome blog"
      }
    }
    assert_redirected_to dashboard_blog_settings_path(@blog.subdomain)
    @blog.reload
    assert_equal "This is my awesome blog", @blog.meta_description
  end

  test "should update blog favicon emoji" do
    sign_in(@user)
    patch dashboard_blog_settings_path(blog_subdomain: @blog.subdomain), params: {
      blog: {
        favicon_emoji: "🚀"
      }
    }
    assert_redirected_to dashboard_blog_settings_path(@blog.subdomain)
    @blog.reload
    assert_equal "🚀", @blog.favicon_emoji
  end

  test "should not update blog for different user" do
    other_user = users(:two)
    sign_in(other_user)

    patch dashboard_blog_settings_path(blog_subdomain: @blog.subdomain), params: {
      blog: {
        title: "Hacked Blog"
      }
    }
    assert_redirected_to dashboard_path
    @blog.reload
    assert_not_equal "Hacked Blog", @blog.title
  end

  test "should create blog when user has none" do
    sign_in(@user)
    # Clear existing blogs
    @user.blogs.destroy_all

    assert_difference("Blog.count", 1) do
      post dashboard_blogs_path, params: {
        blog: {
          title: "New Blog",
          subdomain: "newblog",
          favicon_emoji: "🌟"
        }
      }
    end

    assert_redirected_to dashboard_blog_path("newblog")
    follow_redirect!
    assert_match(/Blog created successfully/, response.body)
  end

  test "should create second blog when user has one" do
    sign_in(@user)
    # User already has one blog (@blog)

    assert_difference("Blog.count", 1) do
      post dashboard_blogs_path, params: {
        blog: {
          title: "Second Blog",
          subdomain: "secondblog",
          favicon_emoji: "🎯"
        }
      }
    end

    assert_redirected_to dashboard_blog_path("secondblog")
    follow_redirect!
    assert_match(/Blog created successfully/, response.body)
  end

  test "should not create third blog when user already has two" do
    sign_in(@user)
    # Create a second blog first
    @user.blogs.create!(
      subdomain: "secondblog",
      title: "Second Blog",
      favicon_emoji: "🎯"
    )

    assert_no_difference("Blog.count") do
      post dashboard_blogs_path, params: {
        blog: {
          title: "Third Blog",
          subdomain: "thirdblog",
          favicon_emoji: "⭐"
        }
      }
    end

    assert_redirected_to dashboard_path
    follow_redirect!
    assert_match(/User cannot have more than 2 blogs/, response.body)
  end
end
