# frozen_string_literal: true

module Sluggable
  module QueryManagement
    extend ActiveSupport::Concern

    def slug_already_exists?
      return false if slug.blank?

      query = self.class.where(slug: slug)
      query = query.where.not(id: id) if persisted?
      query = apply_slug_scope_to_query(query)
      query.exists?
    end

    def next_available_suffix_for_base_slug
      query = self.class.where(base_slug: base_slug)
      query = apply_slug_scope_to_query(query)
      max_suffix = query.maximum(:slug_suffix) || 0
      [ max_suffix + 1, 1 ].max
    end

    def next_available_suffix_for_slug
      query = self.class.where(base_slug: base_slug)
      query = query.where.not(id: id) if persisted?
      query = apply_slug_scope_to_query(query)
      max_suffix = query.maximum(:slug_suffix) || 0
      max_suffix + 1
    end

    def apply_slug_scope_to_query(query)
      scope_attribute = self.class._slug_scope

      if scope_attribute.present? && respond_to?(scope_attribute)
        scope_value = send(scope_attribute)
        query = query.where(scope_attribute => scope_value) if scope_value.present?
      end

      query
    end
  end
end
