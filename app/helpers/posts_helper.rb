module PostsHelper
  def show_post_footer?(post)
    return false if post.author.post_footer_html.blank?
    return false if post.type == "Page" && post.slug == "about"
    true
  end
end
