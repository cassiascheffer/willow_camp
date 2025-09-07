# ABOUTME: Rake task to migrate user data to blogs table for multi-blog architecture
# ABOUTME: Copies blog-related fields from users to blogs and updates post associations
namespace :data do
  desc "Migrate user blog data to blogs table (use DRY_RUN=true for simulation)"
  task migrate_users_to_blogs: :environment do
    dry_run = ENV['DRY_RUN'] == 'true'
    
    if dry_run
      puts "=" * 60
      puts "DRY RUN MODE - No changes will be made to the database"
      puts "=" * 60
    end
    
    puts "Starting migration of user data to blogs..."
    Rails.logger.info "[BlogMigration] Starting user to blog migration (dry_run: #{dry_run})"

    success_count = 0
    error_count = 0
    errors = []
    
    total_users = User.count
    puts "Processing #{total_users} users..."

    User.find_each do |user|
      ActiveRecord::Base.transaction do
        # Find or create blog for this user
        blog = user.blogs.find_or_initialize_by(user_id: user.id)

        if blog.new_record?
          # Set attributes for new blog
          blog.assign_attributes(
            subdomain: user.subdomain,
            title: user.blog_title,
            slug: user.slug,
            meta_description: user.site_meta_description,
            favicon_emoji: user.favicon_emoji,
            custom_domain: user.custom_domain,
            theme: user.theme,
            post_footer_markdown: user.post_footer_markdown,
            post_footer_html: user.post_footer_html,
            no_index: user.no_index
          )

          if dry_run
            puts "  [DRY RUN] Would create blog for user #{user.email} (ID: #{user.id})"
            Rails.logger.info "[BlogMigration][DRY RUN] Would create blog for user #{user.email} with subdomain: #{user.subdomain}"
          else
            # Use insert_all to bypass callbacks and avoid duplicate About page
            # (User already has one created)
            Blog.insert_all([{
              id: SecureRandom.uuid,
              user_id: user.id,
              subdomain: user.subdomain,
              title: user.blog_title,
              slug: user.slug,
              meta_description: user.site_meta_description,
              favicon_emoji: user.favicon_emoji,
              custom_domain: user.custom_domain,
              theme: user.theme,
              post_footer_markdown: user.post_footer_markdown,
              post_footer_html: user.post_footer_html,
              no_index: user.no_index,
              primary: true,  # First blog for user is always primary
              created_at: Time.current,
              updated_at: Time.current
            }])
            puts "  Created blog for user #{user.email} (ID: #{user.id})"
            Rails.logger.info "[BlogMigration] Created blog for user #{user.email} with subdomain: #{user.subdomain}"

            # Reload the blog to get the persisted version
            blog = user.blogs.find_by!(user_id: user.id)
          end
        else
          # Update existing blog with latest user data if needed
          updated_attrs = {}

          # Only update if values differ to avoid unnecessary writes
          updated_attrs[:subdomain] = user.subdomain if blog.subdomain != user.subdomain
          updated_attrs[:title] = user.blog_title if blog.title != user.blog_title
          updated_attrs[:slug] = user.slug if blog.slug != user.slug
          updated_attrs[:meta_description] = user.site_meta_description if blog.meta_description != user.site_meta_description
          updated_attrs[:favicon_emoji] = user.favicon_emoji if blog.favicon_emoji != user.favicon_emoji
          updated_attrs[:custom_domain] = user.custom_domain if blog.custom_domain != user.custom_domain
          updated_attrs[:theme] = user.theme if blog.theme != user.theme
          updated_attrs[:post_footer_markdown] = user.post_footer_markdown if blog.post_footer_markdown != user.post_footer_markdown
          updated_attrs[:post_footer_html] = user.post_footer_html if blog.post_footer_html != user.post_footer_html
          updated_attrs[:no_index] = user.no_index if blog.no_index != user.no_index

          if updated_attrs.any?
            if dry_run
              puts "  [DRY RUN] Would update blog for user #{user.email} (ID: #{user.id}) - changes: #{updated_attrs.keys.join(", ")}"
              Rails.logger.info "[BlogMigration][DRY RUN] Would update blog for user #{user.email}, changes: #{updated_attrs.inspect}"
            else
              blog.update!(updated_attrs)
              puts "  Updated blog for user #{user.email} (ID: #{user.id}) - changed: #{updated_attrs.keys.join(", ")}"
              Rails.logger.info "[BlogMigration] Updated blog for user #{user.email}, changes: #{updated_attrs.inspect}"
            end
          else
            puts "  Blog already up-to-date for user #{user.email} (ID: #{user.id})"
          end
        end

        # Update posts to belong to the blog
        posts_to_update = user.posts.where(blog_id: nil).count
        if posts_to_update > 0
          if dry_run
            puts "    [DRY RUN] Would update #{posts_to_update} posts to belong to blog"
            Rails.logger.info "[BlogMigration][DRY RUN] Would update #{posts_to_update} posts for user #{user.email}"
          else
            posts_updated = 0
            user.posts.where(blog_id: nil).find_each do |post|
              post.update_column(:blog_id, blog.id)
              posts_updated += 1
            end
            puts "    Updated #{posts_updated} posts to belong to blog"
            Rails.logger.info "[BlogMigration] Updated #{posts_updated} posts for user #{user.email}"
          end
        end

        # Update pages to belong to the blog
        pages_to_update = user.pages.where(blog_id: nil).count
        if pages_to_update > 0
          if dry_run
            puts "    [DRY RUN] Would update #{pages_to_update} pages to belong to blog"
            Rails.logger.info "[BlogMigration][DRY RUN] Would update #{pages_to_update} pages for user #{user.email}"
          else
            pages_updated = 0
            user.pages.where(blog_id: nil).find_each do |page|
              page.update_column(:blog_id, blog.id)
              pages_updated += 1
            end
            puts "    Updated #{pages_updated} pages to belong to blog"
            Rails.logger.info "[BlogMigration] Updated #{pages_updated} pages for user #{user.email}"
          end
        end

        success_count += 1
      end
    rescue => e
      error_count += 1
      errors << {user_id: user.id, email: user.email, error: e.message}
      puts "  ERROR: Failed to migrate user #{user.email} (ID: #{user.id}): #{e.message}"
      Rails.logger.error "[BlogMigration] ERROR for user #{user.email}: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
    end

    puts "\n" + "=" * 60
    if dry_run
      puts "DRY RUN SUMMARY:"
      puts "  Would migrate: #{success_count} users"
    else
      puts "Migration Summary:"
      puts "  Successfully migrated: #{success_count} users"
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
      Rails.logger.info "[BlogMigration] Dry run complete. Would have migrated #{success_count} users with #{error_count} errors"
    else
      puts "\nMigration complete!"
      puts "\nNext steps:"
      puts "1. Verify the migration by checking a few users and their blogs"
      puts "2. Update application code to use Blog model instead of User for blog operations"
      puts "3. Run 'rails data:verify_blog_migration' to verify data integrity"
      Rails.logger.info "[BlogMigration] Migration complete. Migrated #{success_count} users with #{error_count} errors"
    end
  end

  desc "Verify blog migration data integrity"
  task verify_blog_migration: :environment do
    puts "Verifying blog migration data integrity..."

    issues = []

    # Check for users without blogs
    users_without_blogs = User.left_joins(:blogs).where(blogs: {id: nil}).count
    if users_without_blogs > 0
      issues << "Found #{users_without_blogs} users without blogs"
    end

    # Check for posts without blog_id
    posts_without_blog = Post.where(blog_id: nil).count
    if posts_without_blog > 0
      issues << "Found #{posts_without_blog} posts without blog_id"
    end

    # Check for pages without blog_id
    pages_without_blog = Page.where(blog_id: nil).count
    if pages_without_blog > 0
      issues << "Found #{pages_without_blog} pages without blog_id"
    end

    # Check for duplicate subdomains between users and blogs
    User.where.not(subdomain: nil).find_each do |user|
      blog = user.blogs.first
      if blog && blog.subdomain != user.subdomain
        issues << "User #{user.email} subdomain (#{user.subdomain}) doesn't match blog subdomain (#{blog.subdomain})"
      end
    end

    # Check for duplicate custom domains between users and blogs
    User.where.not(custom_domain: nil).find_each do |user|
      blog = user.blogs.first
      if blog && blog.custom_domain != user.custom_domain
        issues << "User #{user.email} custom_domain (#{user.custom_domain}) doesn't match blog custom_domain (#{blog.custom_domain})"
      end
    end

    if issues.empty?
      puts "✅ All verification checks passed!"
      puts "  - All users have associated blogs"
      puts "  - All posts have blog_id set"
      puts "  - All pages have blog_id set"
      puts "  - User and blog subdomains match"
      puts "  - User and blog custom domains match"
    else
      puts "⚠️  Found #{issues.count} issues:"
      issues.each do |issue|
        puts "  - #{issue}"
      end
    end
  end

  desc "Rollback blog migration (removes blogs and clears blog_id from posts)"
  task rollback_blog_migration: :environment do
    puts "WARNING: This will delete all blogs and remove blog_id from posts/pages!"
    
    # Safety checks
    total_blogs = Blog.count
    total_posts_with_blog = Post.where.not(blog_id: nil).count
    total_pages_with_blog = Page.where.not(blog_id: nil).count
    
    # Check for multiple blogs per user (would lose data)
    users_with_multiple_blogs = User.joins(:blogs).group("users.id").having("COUNT(blogs.id) > 1").count
    if users_with_multiple_blogs.any?
      puts "\n⚠️  WARNING: #{users_with_multiple_blogs.size} users have multiple blogs!"
      puts "Rolling back will DELETE all secondary blogs and their data!"
    end
    
    # Check for posts without author_id (would become orphaned)
    orphaned_posts = Post.where(author_id: nil).count
    if orphaned_posts > 0
      puts "\n⚠️  WARNING: Found #{orphaned_posts} posts without author_id!"
      puts "These posts will become orphaned after rollback!"
    end
    
    puts "\nThis rollback will affect:"
    puts "  - #{total_blogs} blogs (will be deleted)"
    puts "  - #{total_posts_with_blog} posts with blog_id (will be cleared)"
    puts "  - #{total_pages_with_blog} pages with blog_id (will be cleared)"
    
    Rails.logger.warn "[BlogMigration] Rollback requested. Would affect #{total_blogs} blogs, #{total_posts_with_blog} posts, #{total_pages_with_blog} pages"
    
    puts "\nAre you ABSOLUTELY sure you want to continue? Type 'yes, rollback' to confirm:"

    input = $stdin.gets.strip
    unless input.downcase == "yes, rollback"
      puts "Rollback cancelled."
      Rails.logger.info "[BlogMigration] Rollback cancelled by user"
      exit
    end

    puts "Starting rollback..."
    Rails.logger.warn "[BlogMigration] Starting rollback operation"

    ActiveRecord::Base.transaction do
      # Clear blog_id from all posts and pages
      posts_cleared = Post.where.not(blog_id: nil).update_all(blog_id: nil)
      puts "  Cleared blog_id from #{posts_cleared} posts/pages"
      Rails.logger.info "[BlogMigration] Cleared blog_id from #{posts_cleared} posts/pages"

      # Delete all blogs
      blogs_deleted = Blog.count
      Blog.destroy_all
      puts "  Deleted #{blogs_deleted} blogs"
      Rails.logger.info "[BlogMigration] Deleted #{blogs_deleted} blogs"
    end

    puts "Rollback complete!"
    Rails.logger.warn "[BlogMigration] Rollback complete"
  end
end
