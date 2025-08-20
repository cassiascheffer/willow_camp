require "test_helper"

class OgMetaTagsTest < ActionDispatch::IntegrationTest
  include ActionDispatch::TestProcess::FixtureFile

  setup do
    @user = users(:one)
    @post = posts(:one)
    @headers = {host: "#{@user.subdomain}.willow.camp"}
  end

  test "should render basic og meta tags" do
    get "/#{@post.slug}", headers: @headers
    assert_response :success

    assert_select 'meta[property="og:title"]', 1
    assert_select 'meta[property="og:type"][content="article"]', 1
    assert_select 'meta[property="article:author"]', 1
    assert_select 'meta[property="og:url"]', 1
  end

  test "should render post title and description in meta tags" do
    get "/#{@post.slug}", headers: @headers
    assert_response :success

    doc = Nokogiri::HTML(response.body)

    # Check og:title contains post title
    og_title = doc.css('meta[property="og:title"]').first["content"]
    assert_includes og_title, @post.title

    # Check og:description contains meta description
    og_description = doc.css('meta[property="og:description"]').first["content"]
    assert_includes og_description, @post.meta_description
  end

  test "should have correct og:url pointing to post" do
    get "/#{@post.slug}", headers: @headers
    assert_response :success

    doc = Nokogiri::HTML(response.body)
    og_url = doc.css('meta[property="og:url"]').first["content"]

    assert og_url.include?(@user.subdomain), "URL should include subdomain"
    assert og_url.include?(@post.slug), "URL should include post slug"
  end
end
