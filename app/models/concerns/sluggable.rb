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
    before_validation :ensure_slug_is_set
    before_validation :check_slug_uniqueness

    # Validations
    validates :slug, presence: true, uniqueness: true
    validates :base_slug, presence: true
    validates :slug_suffix, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

    def to_param
      slug
    end

    class_attribute :_slug_source, instance_writer: false

    def self.slug_source(field)
      self._slug_source = field
    end

    def slug_source
      self.class._slug_source || :title
    end
  end

  private

  def slug_source_value
    send(slug_source)
  end

  def slug_source_changed?
    respond_to?(slug_source) && send("#{slug_source}_changed?")
  end

  def ensure_slug_is_set
    return unless needs_slug_update?

    update_base_slug
    update_slug_suffix if needs_suffix_update?
    generate_final_slug
  rescue => e
    Rails.logger.error("Error generating slug: #{e.message}") if defined?(Rails)
    self.slug ||= "#{SecureRandom.hex(5)}"
    self.base_slug ||= self.slug
    self.slug_suffix ||= 0
  end

  def needs_slug_update?
    slug.blank? ||
    base_slug.blank? ||
    (slug_source_changed? && !slug_changed?)
  end

  def needs_suffix_update?
    new_record? || base_slug_changed? || slug_already_exists?
  end

  def update_base_slug
    if custom_slug_provided?
      self.base_slug = slug.to_s.parameterize
    elsif should_regenerate_base_slug?
      self.base_slug = generate_slug_from_title
    end
  end

  def generate_slug_from_title
    slug_source_value.to_s.parameterize.presence || "untitled-#{SecureRandom.hex(3)}"
  end

  def custom_slug_provided?
    slug.present? && (base_slug.blank? || slug_changed?)
  end

  def should_regenerate_base_slug?
    base_slug.blank? ||
    slug.blank? ||
    (!published? && slug_source_changed?)
  end

  def update_slug_suffix
    self.slug_suffix = [ 1, next_available_suffix ].max
  end

  def next_available_suffix
    find_max_slug_suffix + 1
  end

  def find_max_slug_suffix
    return 0 unless existing_slugs_with_same_base?

    @max_slug_suffix ||= self.class
      .where(base_slug: base_slug)
      .where.not(id: id)
      .maximum(:slug_suffix) || 0
  end

  def existing_slugs_with_same_base?
    return false if new_record? && !self.class.exists?(base_slug: base_slug)
    return false if base_slug.blank?
    self.class.where(base_slug: base_slug).where.not(id: id).exists?
  end

  def check_slug_uniqueness
    return if slug.blank?
    return if id.present? && !slug_already_exists?

    update_slug_suffix
    generate_final_slug
  end

  def slug_already_exists?
    return false if slug.blank?
    @slug_exists ||= self.class.where(slug: slug).where.not(id: id).exists?
  end

  def generate_final_slug
    self.slug = if needs_suffix_in_slug?
      "#{base_slug}-#{slug_suffix}"
    else
      base_slug
    end
  end

  def needs_suffix_in_slug?
    slug_suffix > 1
  end
end
