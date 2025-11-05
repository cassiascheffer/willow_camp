require "test_helper"

class Blogs::PostsPaginationTest < ActionDispatch::IntegrationTest
  setup do
    @blog = blogs(:one)
    @user = users(:one)
    @headers = {host: "#{@blog.subdomain}.willow.camp"}

    # Create enough posts to trigger pagination (51 posts, limit is 50)
    51.times do |i|
      Post.create!(
        title: "Pagination Test Post #{i + 1}",
        body_markdown: "# Test Content #{i + 1}\n\nThis is test post number #{i + 1}.",
        author: @user,
        blog: @blog,
        published: true,
        published_at: (i + 1).days.ago
      )
    end
  end

  test "pagination navigation appears when there are more than 50 posts" do
    get posts_url, headers: @headers
    assert_response :success

    # Should see pagination navigation with Pagy 43's series_nav output
    assert_select "nav[aria-label='Posts pagination']"
    # In Pagy 43, the current page is an <a> without href attribute
    assert_select "nav[aria-label='Posts pagination'] a:not([href])", text: "1"
    assert_select "nav[aria-label='Posts pagination'] a[href*='page=2']"
  end

  test "pagination page 2 displays correct content" do
    get posts_url(page: 2), headers: @headers
    assert_response :success

    # Should see page 2 as current (no href attribute for current page)
    assert_select "nav[aria-label='Posts pagination'] a:not([href])", text: "2"
    assert_select "nav[aria-label='Posts pagination'] a[href*='page=1']"

    # Should see posts (ordered by published_at desc)
    assert_select "article", minimum: 1
  end

  test "pagination works on tag pages" do
    # Tag all posts with the same tag
    tag_name = "test-tag"
    @blog.posts.published.each do |post|
      post.tag_list.add(tag_name)
      post.save!
    end

    get tag_url(tag_name), headers: @headers
    assert_response :success

    # Should see pagination navigation
    assert_select "nav[aria-label='Tagged posts pagination']"
    assert_select "nav[aria-label='Tagged posts pagination'] a:not([href])", text: "1"
    assert_select "nav[aria-label='Tagged posts pagination'] a[href*='page=2']"
  end

  test "pagination page 2 works on tag pages" do
    # Tag all posts with the same tag
    tag_name = "test-tag"
    @blog.posts.published.each do |post|
      post.tag_list.add(tag_name)
      post.save!
    end

    get tag_url(tag_name, page: 2), headers: @headers
    assert_response :success

    # Should see page 2 as current (no href attribute)
    assert_select "nav[aria-label='Tagged posts pagination'] a:not([href])", text: "2"
  end

  test "pagination does not appear with fewer posts than limit" do
    # Delete all but 10 posts
    @blog.posts.limit(41).destroy_all

    get posts_url, headers: @headers
    assert_response :success

    # Should NOT see pagination navigation links (may see empty nav container)
    assert_select "nav[aria-label='Posts pagination'] a", count: 0
  end

  test "pagy params are accessible in response" do
    get posts_url, headers: @headers
    assert_response :success

    # Verify @pagy instance was created by checking for pagination in the response
    assert_match(/page=2/, response.body)
  end
end
