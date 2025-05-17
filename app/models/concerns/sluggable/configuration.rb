# frozen_string_literal: true

module Sluggable
  module Configuration
    extend ActiveSupport::Concern

    # Class methods for configuration
    class_methods do
      # Get/set the attribute to use as the source for slug generation
      def slug_source(attribute = nil)
        if attribute.present?
          @_slug_source = attribute
        end
        @_slug_source
      end

      # Accessor for the source attribute
      def _slug_source
        @_slug_source || (superclass.respond_to?(:_slug_source) ? superclass._slug_source : nil)
      end

      # Set a scope for slug uniqueness
      def slug_unique_within_scope(scope_attribute = nil)
        if scope_attribute.present?
          @_slug_scope = scope_attribute
        end
        @_slug_scope
      end

      # Accessor for the scope attribute
      def _slug_scope
        @_slug_scope || (superclass.respond_to?(:_slug_scope) ? superclass._slug_scope : nil)
      end
    end
  end
end
