# ABOUTME: Rake task to migrate user data to blogs table for multi-blog architecture
# ABOUTME: Copies blog-related fields from users to blogs and updates post associations
namespace :data do
  desc "Migrate user blog data to blogs table"
  task migrate_users_to_blogs: :environment do
    puts "Starting migration of user data to blogs..."

    success_count = 0
    error_count = 0
    errors = []

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

          # Reload the blog to get the persisted version
          blog = user.blogs.find_by!(user_id: user.id)
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
            blog.update!(updated_attrs)
            puts "  Updated blog for user #{user.email} (ID: #{user.id}) - changed: #{updated_attrs.keys.join(", ")}"
          else
            puts "  Blog already up-to-date for user #{user.email} (ID: #{user.id})"
          end
        end

        # Update posts to belong to the blog
        posts_updated = 0
        user.posts.where(blog_id: nil).find_each do |post|
          post.update_column(:blog_id, blog.id)
          posts_updated += 1
        end

        if posts_updated > 0
          puts "    Updated #{posts_updated} posts to belong to blog"
        end

        # Update pages to belong to the blog
        pages_updated = 0
        user.pages.where(blog_id: nil).find_each do |page|
          page.update_column(:blog_id, blog.id)
          pages_updated += 1
        end

        if pages_updated > 0
          puts "    Updated #{pages_updated} pages to belong to blog"
        end

        success_count += 1
      end
    rescue => e
      error_count += 1
      errors << {user_id: user.id, email: user.email, error: e.message}
      puts "  ERROR: Failed to migrate user #{user.email} (ID: #{user.id}): #{e.message}"
    end

    puts "\n" + "=" * 60
    puts "Migration Summary:"
    puts "  Successfully migrated: #{success_count} users"
    puts "  Errors encountered: #{error_count} users"

    if errors.any?
      puts "\nErrors:"
      errors.each do |error|
        puts "  User #{error[:email]} (ID: #{error[:user_id]}): #{error[:error]}"
      end
    end

    puts "=" * 60
    puts "\nMigration complete!"
    puts "\nNext steps:"
    puts "1. Verify the migration by checking a few users and their blogs"
    puts "2. Update application code to use Blog model instead of User for blog operations"
    puts "3. Run 'rails data:verify_blog_migration' to verify data integrity"
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
    puts "Are you sure you want to continue? (yes/no)"

    input = $stdin.gets.strip
    unless input.downcase == "yes"
      puts "Rollback cancelled."
      exit
    end

    puts "Starting rollback..."

    ActiveRecord::Base.transaction do
      # Clear blog_id from all posts and pages
      Post.update_all(blog_id: nil)
      puts "  Cleared blog_id from all posts"

      # Delete all blogs
      Blog.destroy_all
      puts "  Deleted all blogs"
    end

    puts "Rollback complete!"
  end
end
