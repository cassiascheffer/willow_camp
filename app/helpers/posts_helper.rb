module PostsHelper
  def show_post_footer?(post)
    return false if post.blog.post_footer_content.blank? && post.blog.read_attribute(:post_footer_html).blank?
    return false if post.type == "Page" && post.slug == "about"
    true
  end
end
