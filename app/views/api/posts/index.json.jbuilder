json.posts do
  json.array! @posts do |post|
    json.partial! "api/posts/post", post: post
    json.slug post.slug
  end
end
