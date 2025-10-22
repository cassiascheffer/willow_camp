# frozen_string_literal: true

# Configure ActiveStorage to serve images through CDN in production
# This replaces the Digital Ocean Spaces endpoint with our CDN domain
# for all ActiveStorage blob URLs.

if Rails.env.production?
  module ActiveStorageCdn
    CDN_HOST = "https://images.willowcamp.ca"
    SPACES_ENDPOINT = ENV.fetch("DIGITAL_OCEAN_SPACES_ENDPOINT", "tor1.digitaloceanspaces.com")

    module CdnUrls
      def url(expires_in: nil, disposition: nil, filename: nil, **options)
        # Get the original URL from the service
        original_url = super

        # Parse and replace the host with our CDN
        uri = URI.parse(original_url)

        # Replace the Digital Ocean Spaces endpoint with our CDN
        spaces_host = ActiveStorageCdn::SPACES_ENDPOINT.gsub("https://", "")
        if uri.host&.include?(spaces_host)
          cdn_uri = URI.parse(ActiveStorageCdn::CDN_HOST)
          uri.host = cdn_uri.host
          uri.scheme = cdn_uri.scheme
        end

        uri.to_s
      end
    end
  end

  Rails.application.config.after_initialize do
    ActiveSupport.on_load(:active_storage_blob) do
      prepend ActiveStorageCdn::CdnUrls
    end
  end
end
