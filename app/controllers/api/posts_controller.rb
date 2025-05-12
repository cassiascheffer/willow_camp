class Api::PostsController < Api::BaseController
  def create
    @post = Post.new(post_params)
    if @post.save
      render json: { post: @post }, status: :created
    else
      render json: { errors: @post.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

    def post_params
      params.require(:post).permit(:title, :body_markdown, :slug, :published, :published_at, :updated_at)
    end
end
