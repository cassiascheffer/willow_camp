class Dashboard::UntitledPostsController < Dashboard::BaseController
  def create
    @post = current_user.posts.create!(
      title: "Untitled",
      published: false
    )

    redirect_to edit_dashboard_post_path(@post.id)
  end
end
