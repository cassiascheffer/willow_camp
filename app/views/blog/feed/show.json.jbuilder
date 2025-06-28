json.version "https://jsonfeed.org/version/1.1"
json.title blog_title_for(@author)
json.home_page_url posts_url(url_options_for(@author))
json.feed_url posts_json_url(url_options_for(@author).merge(format: :json))
json.description "Latest posts from #{@author.name}"

json.items @posts do |post|
  json.id post_url(post.slug, url_options_for(@author))
  json.url post_url(post.slug, url_options_for(@author))
  json.title post.title
  json.content_html sanitize_html_for_feed(post.body_html, request)
  json.content_text post.meta_description.presence || "#{post.title} by #{@author.name}"
  json.date_published post.published_at.iso8601
  json.date_modified post.updated_at.iso8601

  json.author do
    json.name @author.name
  end
end
