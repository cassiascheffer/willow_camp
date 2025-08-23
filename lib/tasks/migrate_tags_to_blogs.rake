# ABOUTME: Rake task to migrate tag tenants from user_id to blog_id for multi-blog architecture
# ABOUTME: Updates tag tenant after users have been migrated to blogs and posts have blog_id set
namespace :data do
  desc "Migrate tag tenants from user_id to blog_id"
  task migrate_tags_to_blogs: :environment do
    puts "Starting migration of tag tenants from user_id to blog_id..."
    puts "IMPORTANT: Run this AFTER running data:migrate_users_to_blogs"
    puts

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
        # Update tenant from user.id to blog.id
        user_taggings.update_all(tenant: blog.id)
        puts "  Updated #{taggings_count} taggings for user #{user.email} (#{user.id} -> #{blog.id})"
        total_taggings += taggings_count
      else
        puts "  No taggings to migrate for user #{user.email}"
      end

      success_count += 1
    rescue => e
      error_count += 1
      errors << {user_id: user.id, email: user.email, error: e.message}
      puts "  ERROR: Failed to migrate tags for user #{user.email} (ID: #{user.id}): #{e.message}"
    end

    puts "\n" + "=" * 60
    puts "Tag Migration Summary:"
    puts "  Successfully processed: #{success_count} users"
    puts "  Total taggings updated: #{total_taggings}"
    puts "  Errors encountered: #{error_count} users"

    if errors.any?
      puts "\nErrors:"
      errors.each do |error|
        puts "  User #{error[:email]} (ID: #{error[:user_id]}): #{error[:error]}"
      end
    end

    puts "=" * 60
    puts "\nTag migration complete!"
    puts "\nNext steps:"
    puts "1. Update Post model: acts_as_taggable_tenant :blog_id"
    puts "2. Update controllers to use blog.id as tenant instead of user.id"
    puts "3. Run 'rails data:verify_tag_blog_migration' to verify data integrity"
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
    puts "Are you sure you want to continue? (yes/no)"

    input = $stdin.gets.strip
    unless input.downcase == "yes"
      puts "Rollback cancelled."
      exit
    end

    puts "Starting tag tenant rollback..."

    total_updated = 0

    User.includes(:blogs).find_each do |user|
      blog = user.blogs.first
      next unless blog

      # Find all taggings where the tenant is this user's blog ID
      blog_taggings = ActsAsTaggableOn::Tagging.where(tenant: blog.id)
      count = blog_taggings.count

      if count > 0
        # Update tenant from blog.id back to user.id
        blog_taggings.update_all(tenant: user.id)
        puts "  Restored #{count} taggings for user #{user.email} (#{blog.id} -> #{user.id})"
        total_updated += count
      end
    end

    puts "Rollback complete! Restored #{total_updated} taggings to use user tenant."
  end
end
