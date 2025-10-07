# This monkey patches the ActsAsTaggableOn::Tag class to add FriendlyId support

require "friendly_id"

# Wait until ActsAsTaggableOn is loaded before applying the patch
Rails.application.config.after_initialize do
  if defined?(ActsAsTaggableOn::Tag)
    # Skip the friendly_id setup if the slug column doesn't exist yet
    # This allows migrations to run without errors
    begin
      if ActiveRecord::Base.connection.table_exists?("tags") &&
          ActiveRecord::Base.connection.column_exists?(:tags, :slug)

        ActsAsTaggableOn::Tag.class_eval do
          extend FriendlyId

          friendly_id :name, use: [:slugged, :finders]

          # Determines when friendly_id should generate a new slug
          def should_generate_new_friendly_id?
            name_changed? || slug.blank?
          end
        end

        # Patch the class methods
        ActsAsTaggableOn::Tag.singleton_class.prepend(Module.new do
          # Override find_or_create_with_like_by_name to ensure slug is generated
          def find_or_create_with_like_by_name(name, *args)
            tag = super
            tag.save if tag.slug.blank? # Generate slug if not present
            tag
          end
        end)

        # Generate slugs for existing tags if they don't have one
        ActsAsTaggableOn::Tag.where(slug: nil).find_each do |tag|
          tag.slug = nil # Force friendly_id to regenerate the slug
          tag.save
        end
      end
    rescue ActiveRecord::NoDatabaseError, ActiveRecord::StatementInvalid => e
      # Silently continue if database doesn't exist yet or has issues
      # This allows rake db:create, db:migrate to work properly
      Rails.logger.debug { "FriendlyId for tags not initialized: #{e.message}" }
    end
  end
end
