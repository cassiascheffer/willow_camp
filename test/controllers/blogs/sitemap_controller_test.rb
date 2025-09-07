require "test_helper"

module Blogs
  class SitemapControllerTest < ActionDispatch::IntegrationTest
    setup do
      @user_one = users(:one)
      @user_two = users(:two)
      @post_one = posts(:one) # Published post by user_one
      @post_two = posts(:two) # Unpublished post by user_two
      @custom_domain_user = users(:custom_domain_user)
      @custom_domain_post = posts(:custom_domain_post)

      # Set up host headers for subdomain-based testing
      @user_one_host = {host: "#{@user_one.subdomain}.willow.camp"}
      @user_two_host = {host: "#{@user_two.subdomain}.willow.camp"}
      @nonexistent_host = {host: "nonexistent.willow.camp"}
      @custom_domain_host = {host: @custom_domain_user.custom_domain}
    end

    test "should get sitemap for user one" do
      get sitemap_path(format: :xml), headers: @user_one_host
      assert_response :success
      assert_equal "application/xml", @response.media_type

      # Check sitemap structure
      assert_match(/<urlset.*xmlns="http:\/\/www\.sitemaps\.org\/schemas\/sitemap\/0\.9"/, @response.body)
      assert_match(/<url>/, @response.body)
      assert_match(/<loc>/, @response.body)
      assert_match(/<lastmod>/, @response.body)
      assert_match(/<changefreq>/, @response.body)
      assert_match(/<priority>/, @response.body)
    end

    test "should get sitemap for user two" do
      get sitemap_path(format: :xml), headers: @user_two_host
      assert_response :success

      # Check sitemap structure
      assert_match(/<urlset.*xmlns="http:\/\/www\.sitemaps\.org\/schemas\/sitemap\/0\.9"/, @response.body)
    end

    test "should return 404 when subdomain does not exist" do
      get sitemap_path(format: :xml), headers: @nonexistent_host
      assert_response :not_found
    end

    test "should only show published posts in sitemap" do
      get sitemap_path(format: :xml), headers: @user_one_host
      assert_response :success
      # Should not include unpublished posts from other users
      assert_not_includes @response.body, @post_two.title
    end

    test "should get sitemap with custom domain" do
      get sitemap_path(format: :xml), headers: @custom_domain_host
      assert_response :success
      assert_equal "application/xml", @response.media_type
    end

    test "should redirect sitemap from subdomain to custom domain" do
      get sitemap_path(format: :xml), headers: {host: "#{@custom_domain_user.subdomain}.willow.camp"}
      assert_redirected_to "https://#{@custom_domain_user.custom_domain}/sitemap.xml"
    end

    test "should not redirect when already on custom domain" do
      get sitemap_path(format: :xml), headers: @custom_domain_host
      assert_response :success
      # Should not be a redirect
      assert_not response.redirect?
    end

    test "should include home page in sitemap" do
      get sitemap_path(format: :xml), headers: @user_one_host
      assert_response :success

      # Check that home page URL is included
      assert_match(/<loc>.*<\/loc>/, @response.body)
    end

    test "should include individual post URLs in sitemap" do
      get sitemap_path(format: :xml), headers: @user_one_host
      assert_response :success

      # Check that individual post URLs are included
      assert_match(/<loc>.*#{@post_one.slug}.*<\/loc>/, @response.body)
    end

    test "should include pages in sitemap" do
      # Create a page for user_one's blog
      blog = @user_one.blogs.where(primary: true).first || @user_one.blogs.create!(subdomain: @user_one.subdomain, title: @user_one.blog_title, primary: true)
      page = Page.create!(
        author: @user_one,
        blog: blog,
        title: "About Page",
        slug: "about-page",
        body_markdown: "This is an about page",
        published: true,
        published_at: Time.current
      )

      get sitemap_path(format: :xml), headers: @user_one_host
      assert_response :success

      # Check that page URL is included
      assert_match(/<loc>.*#{page.slug}.*<\/loc>/, @response.body)
    end

    test "should not include unpublished pages in sitemap" do
      # Create an unpublished page for user_one's blog
      blog = @user_one.blogs.where(primary: true).first || @user_one.blogs.create!(subdomain: @user_one.subdomain, title: @user_one.blog_title, primary: true)
      unpublished_page = Page.create!(
        author: @user_one,
        blog: blog,
        title: "Draft Page",
        slug: "draft",
        body_markdown: "This is a draft",
        published: false
      )

      get sitemap_path(format: :xml), headers: @user_one_host
      assert_response :success

      # Should not include unpublished page
      assert_not_includes @response.body, unpublished_page.slug
    end

    test "should include tags index page in sitemap" do
      get sitemap_path(format: :xml), headers: @user_one_host
      assert_response :success

      # Check that tags index URL is included
      assert_match(/<loc>.*\/tags.*<\/loc>/, @response.body)
    end

    test "should include individual tag pages in sitemap" do
      # Add tags to a post
      @post_one.tag_list = "ruby, rails"
      @post_one.save!

      get sitemap_path(format: :xml), headers: @user_one_host
      assert_response :success

      # Check that individual tag URLs are included
      assert_match(/<loc>.*\/t\/ruby.*<\/loc>/, @response.body)
      assert_match(/<loc>.*\/t\/rails.*<\/loc>/, @response.body)
    end

    test "should include RSS feed URL in sitemap" do
      get sitemap_path(format: :xml), headers: @user_one_host
      assert_response :success

      # Check that RSS feed URL is included
      assert_match(/<loc>.*\/posts\/rss.*<\/loc>/, @response.body)
    end

    test "should include Atom feed URL in sitemap" do
      get sitemap_path(format: :xml), headers: @user_one_host
      assert_response :success

      # Check that Atom feed URL is included
      assert_match(/<loc>.*\/posts\/atom.*<\/loc>/, @response.body)
    end

    test "should include JSON feed URL in sitemap" do
      get sitemap_path(format: :xml), headers: @user_one_host
      assert_response :success

      # Check that JSON feed URL is included
      assert_match(/<loc>.*\/posts\/json.*<\/loc>/, @response.body)
    end

    test "should include subscribe page in sitemap" do
      get sitemap_path(format: :xml), headers: @user_one_host
      assert_response :success

      # Check that subscribe page URL is included
      assert_match(/<loc>.*\/subscribe.*<\/loc>/, @response.body)
    end

    test "should set proper priorities for different URL types" do
      get sitemap_path(format: :xml), headers: @user_one_host
      assert_response :success

      # Home page should have highest priority
      assert_match(/<priority>1\.0<\/priority>/, @response.body)

      # Posts should have high priority
      assert_match(/<priority>0\.9<\/priority>/, @response.body)

      # Tags index should have good priority
      assert_match(/<priority>0\.8<\/priority>/, @response.body)
    end

    test "should set proper changefreq for different URL types" do
      get sitemap_path(format: :xml), headers: @user_one_host
      assert_response :success

      # Home page should update daily
      assert_match(/<changefreq>daily<\/changefreq>/, @response.body)

      # Posts should update monthly
      assert_match(/<changefreq>monthly<\/changefreq>/, @response.body)

      # Feeds should update hourly
      assert_match(/<changefreq>hourly<\/changefreq>/, @response.body)
    end

    test "should handle case insensitive custom domain" do
      get sitemap_path(format: :xml), headers: {host: @custom_domain_user.custom_domain}
      assert_response :success
    end

    test "should handle subdomain with willow.camp domain" do
      get sitemap_path(format: :xml), headers: {host: "#{@user_one.subdomain}.willow.camp"}
      assert_response :success
    end

    test "should return XML format by default" do
      get sitemap_path(format: :xml), headers: @user_one_host
      assert_response :success
      assert_equal "application/xml", @response.media_type
    end

    test "should include proper XML declaration" do
      get sitemap_path(format: :xml), headers: @user_one_host
      assert_response :success
      assert_match(/<\?xml version="1\.0" encoding="UTF-8"\?>/, @response.body)
    end

    test "should limit posts in sitemap to 500 most recent" do
      # First check how many posts already exist
      @user_one.posts.published.not_page.count

      # Get or create the blog for user_one
      blog = @user_one.blogs.where(primary: true).first || @user_one.blogs.create!(subdomain: @user_one.subdomain, title: @user_one.blog_title, primary: true)

      # Create enough posts to exceed the limit
      505.times do |i|
        Post.create!(
          author: @user_one,
          blog: blog,
          title: "Post #{i}",
          slug: "post-#{i}",
          body_markdown: "Content for post #{i}",
          published: true,
          published_at: i.days.ago
        )
      end

      get sitemap_path(format: :xml), headers: @user_one_host
      assert_response :success

      # Count all post URLs in the sitemap
      all_post_urls = @response.body.scan(/<loc>.*\/[^\/]+<\/loc>/)

      # Filter to just blog post URLs (exclude home, tags, feeds, etc)
      post_urls = all_post_urls.select { |url| url =~ /post-\d+/ || url.include?(@post_one.slug) }

      # Should have exactly 500 post URLs total
      assert_equal 500, post_urls.count, "Sitemap should contain exactly 500 posts"

      # Should include the most recent posts
      assert_match(/post-0/, @response.body)

      # Should not include the oldest posts
      assert_not_includes @response.body, "post-504"
    end
  end
end
