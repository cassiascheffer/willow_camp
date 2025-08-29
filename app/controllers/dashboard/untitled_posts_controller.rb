class Dashboard::UntitledPostsController < Dashboard::BlogBaseController
  def create
    @post = current_blog.posts.create!(
      title: "Untitled",
      published: false,
      author: current_user
    )

    redirect_to edit_dashboard_post_path(blog_subdomain: current_blog.subdomain, id: @post.id)
  end
end
