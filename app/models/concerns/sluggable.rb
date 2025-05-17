# frozen_string_literal: true

# The Sluggable concern provides automatic slug generation and management
# for ActiveRecord models. It ensures slugs are:
# - Generated from the title attribute by default
# - Always unique within the model class
# - Only updated for unpublished records when title changes
# - Properly formatted with numeric suffixes when duplicates exist
#
# Required attributes in the including model:
# - title: string - Used to generate the slug
# - slug: string - The final, unique URL-friendly identifier
# - base_slug: string - The initial slug without suffix
# - slug_suffix: integer - Numeric suffix used to ensure uniqueness
# - published: boolean - Controls whether title changes affect the slug
#
# For optimal performance, add the following indexes:
# - add_index :table_name, :slug, unique: true
# - add_index :table_name, :base_slug
#
# This concern is organized into several modules:
# - Sluggable::Configuration - Class configuration methods
# - Sluggable::Generation - Core slug generation logic
# - Sluggable::ErrorHandling - Error handling and logging
# - Sluggable::QueryManagement - Database query methods

require_relative "sluggable/error_handling"
require_relative "sluggable/configuration"
require_relative "sluggable/generation"
require_relative "sluggable/query_management"
#
# Slug Generation Flow:
#
#                            START
#                              |
#                              v
#              +---------------------------------+
#              | before_validation: ensure_slug  |
#              +---------------------------------+
#                              |
#                              v
# +-----------------------------------------------------------------+
# | needs_slug_update?                                              |
# |                                                                 |
# | IF (slug.blank? OR                                              |
# |     base_slug.blank? OR                                         |
# |     (slug_source_changed? AND !slug_changed?))                  |
# +-----------------------------------------------------------------+
#                              |
#           +-----------------+ +-------------------+
#           |                                       |
#           | YES                                   | NO
#           v                                       v
# +-----------------------------+       +------------------------+
# | update_base_slug            |       | Skip slug update       |
# |                             |       | (return from method)   |
# | Custom slug provided?       |       +------------------------+
# +-----------------------------+
#           |
#  +--------+ +----------+
#  |                     |
#  | YES                 | NO
#  v                     v
# +----------------+    +-------------------------+
# | base_slug =    |    | Should regenerate?      |
# | slug.param     |    | IF (base_slug.blank? OR |
# +----------------+    |     slug.blank? OR      |
#  |                    |     (!published? AND    |
#  |                    |      source_changed?))  |
#  |                    +-------------------------+
#  |                     |
#  |             +-------+ +--------+
#  |             |                  |
#  |             | YES              | NO
#  |             v                  v
#  |    +----------------+    +----------------+
#  |    | base_slug =    |    | Keep existing  |
#  |    | source.param   |    | base_slug      |
#  |    +----------------+    +----------------+
#  |             |                  |
#  +-------------+------------------+
#                |
#                v
# +---------------------------------------------------+
# | needs_suffix_update?                              |
# |                                                   |
# | IF (new_record? OR                                |
# |     base_slug_changed? OR                         |
# |     slug_already_exists?)                         |
# +---------------------------------------------------+
#                |
#       +--------+ +--------+
#       |                   |
#       | YES               | NO
#       v                   v
# +-------------------+    +-----------------+
# | update_slug_suffix|    | Keep existing   |
# |                   |    | slug_suffix     |
# | suffix = max + 1  |    +-----------------+
# | (at least 1)      |            |
# +-------------------+            |
#       |                          |
#       +--------------------------+
#                |
#                v
# +-------------------------------------------+
# | generate_final_slug                       |
# |                                           |
# | IF (slug_suffix > 1)                      |
# |    slug = "#{base_slug}-#{slug_suffix}"   |
# | ELSE                                      |
# |    slug = base_slug                       |
# +-------------------------------------------+
#                |
#                v
# +---------------------------------------------------+
# | before_validation: check_slug_uniqueness          |
# |                                                   |
# | IF (slug.blank? OR                                |
# |    (id.present? AND !slug_already_exists?))       |
# |    → return (no action needed)                    |
# | ELSE                                              |
# |    → update_slug_suffix                           |
# |    → generate_final_slug                          |
# +---------------------------------------------------+
#                |
#                v
#              FINISH
#
module Sluggable
  extend ActiveSupport::Concern

  included do
    # Include all modular components
    include Sluggable::Configuration
    include Sluggable::ErrorHandling
    include Sluggable::Generation
    include Sluggable::QueryManagement

    before_validation :ensure_slug
    before_validation :verify_slug_uniqueness

    validates :slug, presence: true
    validates :base_slug, presence: true
    validates :slug_suffix, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

    def to_param
      slug
    end
  end

  # Return the configured slug source field or default to 'title'
  def slug_source
    self.class._slug_source || :title
  end

  private

  # Core workflow method
  def ensure_slug
    # Skip if we don't need to update
    return unless needs_slug_update?

    # Update components of the slug
    set_base_slug
    set_slug_suffix if needs_slug_suffix_update?
    generate_final_slug
  rescue ErrorHandling::SlugGenerationError => e
    # Log specific slug errors with context
    log_slug_error(e)
    set_fallback_slug
  rescue StandardError => e
    # Handle unexpected errors
    log_slug_error(ErrorHandling::SlugGenerationFailedError.new("Unexpected error: #{e.message}"))
    set_fallback_slug
  end

  # Determine if the slug needs updating
  def needs_slug_update?
    slug.blank? ||
    base_slug.blank? ||
    (slug_source_changed? && !slug_changed?)
  end

  # Check if the slug source field has changed
  def slug_source_changed?
    respond_to?(slug_source) && send("#{slug_source}_changed?")
  end

  # Generate the final slug from base_slug and suffix
  def generate_final_slug
    self.slug = needs_suffix_in_slug? ? "#{base_slug}-#{slug_suffix}" : base_slug
  end

  # Determine if we need to append suffix to the slug
  def needs_suffix_in_slug?
    slug_suffix > 1
  end
end
