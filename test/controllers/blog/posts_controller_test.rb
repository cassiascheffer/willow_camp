require "test_helper"

class Blog::PostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @post = posts(:one)
    @user = users(:one)
    @custom_domain_user = users(:custom_domain_user)
    @custom_domain_post = posts(:custom_domain_post)

    host = "#{@user.subdomain}.willow.camp"
    @headers = {host: host}
  end

  test "should get index" do
    get posts_url, headers: @headers
    assert_response :success
  end

  test "should show post" do
    get "/my-post", headers: {host: "#{@user.subdomain}.willow.camp"}
    assert_response :success
  end

  test "should find user by subdomain" do
    get posts_url, headers: {host: "#{@user.subdomain}.willow.camp"}
    assert_response :success
    assert_select "title", text: /#{@user.blog_title}/i
  end

  test "should find user by custom domain" do
    get posts_url, headers: {host: @custom_domain_user.custom_domain}
    assert_response :success
    assert_select "title", text: /#{@custom_domain_user.blog_title}/i
  end

  test "should redirect to main site when user not found" do
    get posts_url, headers: {host: "nonexistent.willow.camp"}
    assert_redirected_to root_url(subdomain: false)
  end

  test "should redirect to custom domain when user has one" do
    # Access via subdomain when user has custom domain
    get posts_url, headers: {host: "#{@custom_domain_user.subdomain}.willow.camp"}
    assert_redirected_to "https://#{@custom_domain_user.custom_domain}/"
  end

  test "should not redirect when already on custom domain" do
    # Access via custom domain - should not redirect
    get posts_url, headers: {host: @custom_domain_user.custom_domain}
    assert_response :success
    assert_select "title", text: /#{@custom_domain_user.blog_title}/i
  end

  test "should handle post show with custom domain" do
    get "/#{@custom_domain_post.slug}", headers: {host: @custom_domain_user.custom_domain}
    assert_response :success
    assert_select "h1", text: @custom_domain_post.title
  end

  test "should redirect post show to custom domain" do
    get "/#{@custom_domain_post.slug}", headers: {host: "#{@custom_domain_user.subdomain}.willow.camp"}
    assert_redirected_to "https://#{@custom_domain_user.custom_domain}/#{@custom_domain_post.slug}"
  end

  test "should handle subdomain with no custom domain normally" do
    get posts_url, headers: {host: "#{@user.subdomain}.willow.camp"}
    assert_response :success
    assert_select "title", text: /#{@user.blog_title}/i
  end

  test "should handle case insensitive domain matching" do
    get posts_url, headers: {host: @custom_domain_user.custom_domain}
    assert_response :success
    assert_select "title", text: /#{@custom_domain_user.blog_title}/i
  end

  test "should return 404 for non-existent post with JSON format" do
    get "/nonexistent-post.json", headers: {host: "#{@user.subdomain}.willow.camp"}
    assert_response :not_found
    assert_equal "application/json", response.media_type
  end

  test "should return 404 HTML for non-existent post with HTML format" do
    get "/nonexistent-post", headers: {host: "#{@user.subdomain}.willow.camp"}
    assert_response :not_found
    assert_equal "text/html", response.media_type
  end

  test "should display featured posts section when featured posts exist" do
    featured_post = create(:post, author: @user, featured: true, published: true)
    
    get posts_url, headers: @headers
    assert_response :success
    
    assert_select "h2", text: "Featured"
    assert_select "article.post-summary" do
      assert_select "h3", text: featured_post.title
    end
  end

  test "should not display featured posts section when no featured posts exist" do
    # Ensure no featured posts exist
    @user.posts.update_all(featured: false)
    
    get posts_url, headers: @headers
    assert_response :success
    
    assert_select "h2", text: "Featured", count: 0
  end

  test "should limit featured posts to 3" do
    # Create 5 featured posts
    5.times do |i|
      create(:post, author: @user, featured: true, published: true, 
             published_at: i.days.ago, title: "Featured Post #{i}")
    end
    
    get posts_url, headers: @headers
    assert_response :success
    
    # Should only show 3 featured posts
    assert_select ".card-body h2", text: "Featured" do
      assert_select "+ div article.post-summary", count: 3
    end
  end

  test "should order featured posts by published_at desc" do
    oldest_featured = create(:post, author: @user, featured: true, published: true, 
                             published_at: 3.days.ago, title: "Oldest Featured")
    newest_featured = create(:post, author: @user, featured: true, published: true, 
                             published_at: 1.day.ago, title: "Newest Featured")
    middle_featured = create(:post, author: @user, featured: true, published: true, 
                             published_at: 2.days.ago, title: "Middle Featured")
    
    get posts_url, headers: @headers
    assert_response :success
    
    # Check that featured posts are in correct order
    featured_section = css_select(".card-body h2:contains('Featured') + div")
    assert featured_section.any?
    
    articles = css_select("article.post-summary h3")
    featured_titles = articles.first(3).map(&:text)
    
    assert_equal "Newest Featured", featured_titles[0]
    assert_equal "Middle Featured", featured_titles[1] 
    assert_equal "Oldest Featured", featured_titles[2]
  end

  test "should only show published featured posts" do
    published_featured = create(:post, author: @user, featured: true, published: true, title: "Published Featured")
    draft_featured = create(:post, author: @user, featured: true, published: false, title: "Draft Featured")
    
    get posts_url, headers: @headers
    assert_response :success
    
    assert_select "h3", text: "Published Featured"
    assert_select "h3", text: "Draft Featured", count: 0
  end

  test "should show meta description for featured posts when present" do
    featured_post = create(:post, author: @user, featured: true, published: true,
                          title: "Featured with Meta", meta_description: "This is a test meta description")
    
    get posts_url, headers: @headers
    assert_response :success
    
    assert_select "p", text: "This is a test meta description"
  end

  test "should not show meta description element when not present for featured posts" do
    featured_post = create(:post, author: @user, featured: true, published: true,
                          title: "Featured without Meta", meta_description: nil)
    
    get posts_url, headers: @headers
    assert_response :success
    
    # Should have the featured post title but no meta description paragraph
    assert_select "h3", text: "Featured without Meta"
    assert_select "article.post-summary p", count: 0
  end
end
