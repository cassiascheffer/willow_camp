# ABOUTME: Rake task to migrate tag tenants from user_id to blog_id for multi-blog architecture
# ABOUTME: Updates tag tenant after users have been migrated to blogs and posts have blog_id set
namespace :data do
  desc "Migrate tag tenants from user_id to blog_id (use DRY_RUN=true for simulation)"
  task migrate_tags_to_blogs: :environment do
    dry_run = ENV['DRY_RUN'] == 'true'
    
    if dry_run
      puts "=" * 60
      puts "DRY RUN MODE - No changes will be made to the database"
      puts "=" * 60
    end
    
    puts "Starting migration of tag tenants from user_id to blog_id..."
    puts "IMPORTANT: Run this AFTER running data:migrate_users_to_blogs"
    puts
    
    Rails.logger.info "[TagMigration] Starting tag tenant migration (dry_run: #{dry_run})"

    # Verify prerequisites
    users_without_blogs = User.left_joins(:blogs).where(blogs: {id: nil}).count
    if users_without_blogs > 0
      puts "❌ ERROR: Found #{users_without_blogs} users without blogs."
      puts "Please run 'rails data:migrate_users_to_blogs' first."
      exit 1
    end

    posts_without_blog = Post.where(blog_id: nil).count
    if posts_without_blog > 0
      puts "❌ ERROR: Found #{posts_without_blog} posts without blog_id."
      puts "Please run 'rails data:migrate_users_to_blogs' first to associate posts with blogs."
      exit 1
    end

    puts "✅ Prerequisites met - all users have blogs and all posts have blog_id"
    puts

    success_count = 0
    error_count = 0
    errors = []
    total_taggings = 0

    User.includes(:blogs).find_each do |user|
      blog = user.blogs.first # Assuming one blog per user for now
      next unless blog

      # Find all taggings where the tenant is this user's ID
      user_taggings = ActsAsTaggableOn::Tagging
        .joins(:tag)
        .where(tenant: user.id)

      taggings_count = user_taggings.count
      if taggings_count > 0
        if dry_run
          puts "  [DRY RUN] Would update #{taggings_count} taggings for user #{user.email} (#{user.id} -> #{blog.id})"
          Rails.logger.info "[TagMigration][DRY RUN] Would update #{taggings_count} taggings for user #{user.email}"
        else
          # Update tenant from user.id to blog.id
          user_taggings.update_all(tenant: blog.id)
          puts "  Updated #{taggings_count} taggings for user #{user.email} (#{user.id} -> #{blog.id})"
          Rails.logger.info "[TagMigration] Updated #{taggings_count} taggings for user #{user.email} (#{user.id} -> #{blog.id})"
        end
        total_taggings += taggings_count
      else
        puts "  No taggings to migrate for user #{user.email}"
      end

      success_count += 1
    rescue => e
      error_count += 1
      errors << {user_id: user.id, email: user.email, error: e.message}
      puts "  ERROR: Failed to migrate tags for user #{user.email} (ID: #{user.id}): #{e.message}"
      Rails.logger.error "[TagMigration] ERROR for user #{user.email}: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
    end

    puts "\n" + "=" * 60
    if dry_run
      puts "DRY RUN SUMMARY:"
      puts "  Would process: #{success_count} users"
      puts "  Would update: #{total_taggings} taggings"
    else
      puts "Tag Migration Summary:"
      puts "  Successfully processed: #{success_count} users"
      puts "  Total taggings updated: #{total_taggings}"
    end
    puts "  Errors encountered: #{error_count} users"

    if errors.any?
      puts "\nErrors:"
      errors.each do |error|
        puts "  User #{error[:email]} (ID: #{error[:user_id]}): #{error[:error]}"
      end
    end

    puts "=" * 60
    
    if dry_run
      puts "\nDRY RUN COMPLETE - No changes were made"
      puts "To run the actual migration, run without DRY_RUN=true"
      Rails.logger.info "[TagMigration] Dry run complete. Would have processed #{success_count} users, #{total_taggings} taggings"
    else
      puts "\nTag migration complete!"
      puts "\nNext steps:"
      puts "1. Update Post model: acts_as_taggable_tenant :blog_id"
      puts "2. Update controllers to use blog.id as tenant instead of user.id"
      puts "3. Run 'rails data:verify_tag_blog_migration' to verify data integrity"
      Rails.logger.info "[TagMigration] Migration complete. Processed #{success_count} users, updated #{total_taggings} taggings"
    end
  end

  desc "Verify tag blog migration data integrity"
  task verify_tag_blog_migration: :environment do
    puts "Verifying tag blog migration data integrity..."

    issues = []

    # Check for taggings still using user IDs as tenant
    user_ids = User.pluck(:id)
    taggings_with_user_tenant = ActsAsTaggableOn::Tagging.where(tenant: user_ids).count
    if taggings_with_user_tenant > 0
      issues << "Found #{taggings_with_user_tenant} taggings still using user ID as tenant"
    end

    # Check for taggings using blog IDs as tenant
    blog_ids = Blog.pluck(:id)
    taggings_with_blog_tenant = ActsAsTaggableOn::Tagging.where(tenant: blog_ids).count
    total_taggings = ActsAsTaggableOn::Tagging.count

    puts "Total taggings: #{total_taggings}"
    puts "Taggings with blog tenant: #{taggings_with_blog_tenant}"
    puts "Taggings with user tenant: #{taggings_with_user_tenant}"

    # Check for orphaned taggings (tenant not matching any blog)
    orphaned_count = ActsAsTaggableOn::Tagging.where.not(tenant: blog_ids).where.not(tenant: nil).count
    if orphaned_count > 0
      issues << "Found #{orphaned_count} taggings with orphaned tenant IDs"
    end

    if issues.empty?
      puts "✅ All verification checks passed!"
      puts "  - All taggings are using blog IDs as tenants"
      puts "  - No orphaned tenant IDs found"
      puts "  - Ready to switch application code to use blog tenant"
    else
      puts "⚠️  Found #{issues.count} issues:"
      issues.each do |issue|
        puts "  - #{issue}"
      end
    end
  end

  desc "Rollback tag migration (restore user IDs as tenants)"
  task rollback_tag_blog_migration: :environment do
    puts "WARNING: This will restore user IDs as tag tenants!"
    
    # Safety checks
    blog_ids = Blog.pluck(:id)
    taggings_with_blog_tenant = ActsAsTaggableOn::Tagging.where(tenant: blog_ids).count
    
    # Check for users with multiple blogs (ambiguous rollback)
    users_with_multiple_blogs = User.joins(:blogs).group("users.id").having("COUNT(blogs.id) > 1").count
    if users_with_multiple_blogs.any?
      puts "\n⚠️  WARNING: #{users_with_multiple_blogs.size} users have multiple blogs!"
      puts "Rollback may not correctly restore tags to the original state for these users."
    end
    
    puts "\nThis rollback will affect:"
    puts "  - #{taggings_with_blog_tenant} taggings with blog tenant (will be restored to user tenant)"
    
    Rails.logger.warn "[TagMigration] Rollback requested. Would affect #{taggings_with_blog_tenant} taggings"
    
    puts "\nAre you ABSOLUTELY sure you want to continue? Type 'yes, rollback' to confirm:"

    input = $stdin.gets.strip
    unless input.downcase == "yes, rollback"
      puts "Rollback cancelled."
      Rails.logger.info "[TagMigration] Rollback cancelled by user"
      exit
    end

    puts "Starting tag tenant rollback..."
    Rails.logger.warn "[TagMigration] Starting rollback operation"

    total_updated = 0
    errors = 0

    User.includes(:blogs).find_each do |user|
      begin
        blog = user.blogs.first
        next unless blog

        # Find all taggings where the tenant is this user's blog ID
        blog_taggings = ActsAsTaggableOn::Tagging.where(tenant: blog.id)
        count = blog_taggings.count

        if count > 0
          # Update tenant from blog.id back to user.id
          blog_taggings.update_all(tenant: user.id)
          puts "  Restored #{count} taggings for user #{user.email} (#{blog.id} -> #{user.id})"
          Rails.logger.info "[TagMigration] Restored #{count} taggings for user #{user.email}"
          total_updated += count
        end
      rescue => e
        errors += 1
        puts "  ERROR: Failed to rollback tags for user #{user.email}: #{e.message}"
        Rails.logger.error "[TagMigration] Rollback error for user #{user.email}: #{e.message}"
      end
    end

    puts "\nRollback complete!"
    puts "  Restored #{total_updated} taggings to use user tenant"
    puts "  Errors: #{errors}" if errors > 0
    Rails.logger.warn "[TagMigration] Rollback complete. Restored #{total_updated} taggings with #{errors} errors"
  end
end
