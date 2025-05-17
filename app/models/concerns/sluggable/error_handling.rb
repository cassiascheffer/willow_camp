# frozen_string_literal: true

module Sluggable
  module ErrorHandling
    extend ActiveSupport::Concern

    # Custom error classes
    class SlugGenerationError < StandardError; end
    class InvalidSlugSourceError < SlugGenerationError; end
    class SlugGenerationFailedError < SlugGenerationError; end

    # Log slug errors with context
    def log_slug_error(error)
      Rails.logger.error("Slug generation error for #{self.class.name} ##{id || 'new'}: #{error.message}")
    end

    # Set a fallback slug when normal generation fails
    def set_fallback_slug
      # Use the ID if available, or a timestamp to ensure uniqueness
      fallback_base = id.present? ? "record-#{id}" : "record-#{Time.current.to_i}"

      # Set fallback slug components
      self.base_slug = fallback_base unless base_slug.present?
      self.slug_suffix = 1 unless slug_suffix.present?
      self.slug = base_slug
    end
  end
end
