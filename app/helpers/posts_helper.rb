module PostsHelper
  def show_post_footer?(post)
    return false unless post.author.post_footer_html.present?
    return false if post.type == "Page" && post.slug == "about"
    true
  end
end
