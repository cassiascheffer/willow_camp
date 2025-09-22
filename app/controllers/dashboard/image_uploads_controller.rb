# ABOUTME: Controller for handling TinyMCE image uploads with Active Storage
# ABOUTME: Attaches uploaded images to posts via the content_images association

class Dashboard::ImageUploadsController < Dashboard::BlogBaseController
  before_action :set_post

  def create
    if params[:file].present?
      @post.content_images.attach(params[:file])

      if @post.content_images.last
        image = @post.content_images.last
        render json: {
          location: rails_blob_url(image)
        }
      else
        render json: {error: "Failed to attach image"}, status: :unprocessable_entity
      end
    else
      render json: {error: "No file provided"}, status: :bad_request
    end
  rescue => e
    Rails.logger.error "Image upload failed: #{e.message}"
    render json: {error: "Upload failed: #{e.message}"}, status: :internal_server_error
  end

  private

  def set_post
    @post = @blog.posts.friendly.find(params[:post_id])
  rescue ActiveRecord::RecordNotFound
    render json: {error: "Post not found"}, status: :not_found
  end
end
