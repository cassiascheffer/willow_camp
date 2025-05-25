json.post do
  json.id @post.id
  json.slug @post.slug
  json.markdown render_markdown_with_frontmatter(@post)
end
