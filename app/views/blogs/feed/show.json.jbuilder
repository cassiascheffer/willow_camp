json.version "https://jsonfeed.org/version/1.1"
json.title blog_title_for(@blog)
json.home_page_url posts_url(url_options_for(@blog))
json.feed_url posts_json_url(url_options_for(@blog).merge(format: :json))
json.description "Latest posts from #{@blog.user.name}"

json.items @posts do |post|
  json.id post_url(post.slug, url_options_for(@blog))
  json.url post_url(post.slug, url_options_for(@blog))
  json.title post.title
  json.content_html sanitize_html_for_feed(post.body_html, request)
  json.content_text post.meta_description.presence || "#{post.title} by #{@blog.user.name}"
  json.date_published post.published_at.iso8601
  json.date_modified post.updated_at.iso8601

  json.author do
    json.name @blog.user.name
  end
end
