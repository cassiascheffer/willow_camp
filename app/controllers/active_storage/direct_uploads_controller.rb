# ABOUTME: Override Active Storage direct uploads to properly set public ACL header
# ABOUTME: Ensures images uploaded via Marksmith are publicly accessible on Digital Ocean Spaces

class ActiveStorage::DirectUploadsController < ActiveStorage::BaseController
  def create
    blob = ActiveStorage::Blob.create_before_direct_upload!(**blob_args)
    render json: direct_upload_json(blob)
  end

  private

  def blob_args
    params.require(:blob).permit(:filename, :byte_size, :checksum, :content_type, metadata: {}).to_h.symbolize_keys
  end

  def direct_upload_json(blob)
    response = blob.as_json(root: false, methods: :signed_id)

    # Get the standard direct upload configuration
    direct_upload = {
      url: blob.service_url_for_direct_upload,
      headers: blob.service_headers_for_direct_upload
    }

    # Add the public-read ACL header for Digital Ocean Spaces
    if Rails.application.config.active_storage.service == :digitalocean
      direct_upload[:headers]["x-amz-acl"] = "public-read"
    end

    response.merge(direct_upload: direct_upload)
  end
end
