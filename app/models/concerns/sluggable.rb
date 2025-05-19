module Sluggable
  extend ActiveSupport::Concern

  included do
    before_validation :set_slug
    validates :slug, uniqueness: { scope: :author_id }

    class_attribute :slug_source_field, default: :title
    class_attribute :slug_scope_field
  end

  class_methods do
    def slug_source(source_field)
      self.slug_source_field = source_field || :title
    end

    def slug_unique_within_scope(scope_field)
      self.slug_scope_field = scope_field || :author_id
    end
  end

  def slug_source_value
    public_send(self.class.slug_source_field)
  end

  def generate_base_slug
    source = slug_source_value&.to_s
    return nil if source.blank?

    source.parameterize
  end

  def should_update_slug?
    # Update slug if:
    # 1. No slug exists yet, OR
    # 2. The model is not published yet (allows changing slugs for draft content)
    slug.blank? || !published?
  end

  def set_slug
    if slug_changed? && !slug.nil?
      self.base_slug = slug
      self.slug_suffix = new_slug_suffix
      generate_complete_slug
      return
    end

    # Only generate a new base_slug if:
    # 1. base_slug is blank (new record), OR
    # 2. The model is unpublished (draft content can have slug changes)
    if base_slug.blank? || should_update_slug?
      new_base_slug = generate_base_slug
      return if new_base_slug.blank?

      self.base_slug = new_base_slug
      # Reset suffix when base_slug changes
      self.slug_suffix = new_slug_suffix
    end

    # Ensure slug suffix is at least 1
    self.slug_suffix = 1 if self.slug_suffix.nil? || self.slug_suffix < 1

    generate_complete_slug
  end

  def generate_complete_slug
    return if base_slug.blank?

    if slug_suffix == 1
      self.slug = base_slug
    else
      self.slug = "#{base_slug}-#{slug_suffix}"
    end
  end

  def new_slug_suffix
    scope_field = self.class.slug_scope_field || :author_id
    self.slug_suffix = self.class.where(scope_field => self[scope_field])
        .where.not(id: id)
        .where(base_slug: base_slug)
        .maximum(:slug_suffix).to_i + 1
  end
end
