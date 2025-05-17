# frozen_string_literal: true

module Sluggable
  module Generation
    extend ActiveSupport::Concern

    def set_base_slug
      if slug_changed? && slug.present?
        self.base_slug = slug.parameterize
      elsif should_regenerate_base_slug?
        source_value = send(slug_source) if respond_to?(slug_source)

        if source_value.blank?
          raise ErrorHandling::InvalidSlugSourceError.new("Slug source '#{slug_source}' is blank")
        end

        self.base_slug = source_value.to_s.parameterize
      end
    end

    def should_regenerate_base_slug?
      base_slug.blank? ||
      slug.blank? ||
      (!respond_to?(:published?) || !published?) && slug_source_changed?
    end

    def set_slug_suffix
      self.slug_suffix = 1

      if needs_slug_suffix_update?
        self.slug_suffix = next_available_suffix_for_base_slug
      end
    end

    def needs_slug_suffix_update?
      new_record? ||
      base_slug_changed? ||
      slug_already_exists?
    end

    def verify_slug_uniqueness
      return if slug.blank? || (id.present? && !slug_already_exists?)

      set_slug_suffix
      generate_final_slug
    end
  end
end
