json.post do
  json.id @post.id
  json.slug @post.slug
  json.title @post.title
  json.published @post.published
  json.meta_description @post.meta_description
  json.published_at @post.published_at
  json.tag_list @post.tag_list
  json.markdown render_markdown_with_frontmatter(@post)
  json.errors @post.errors if @post.errors.any?
end
