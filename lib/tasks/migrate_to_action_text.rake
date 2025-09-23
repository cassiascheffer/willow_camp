# ABOUTME: Rake task to migrate existing body_html and post_footer_html content to ActionText
# ABOUTME: This is a one-time migration to move from text columns to ActionText rich_text fields

namespace :action_text do
  desc "Migrate existing HTML content to ActionText"
  task migrate_content: :environment do
    puts "Starting migration of HTML content to ActionText..."

    # Migrate Post body_html to body_content
    posts_count = 0
    posts_with_content = Post.where.not(body_html: [nil, ""])
    total_posts = posts_with_content.count

    puts "Found #{total_posts} posts with body_html to migrate"

    posts_with_content.find_each do |post|
      if post.body_content.blank? && post.read_attribute(:body_html).present?
        post.body_content = post.read_attribute(:body_html)
        if post.save(validate: false)
          posts_count += 1
          print "." if posts_count % 10 == 0
        else
          puts "\nFailed to migrate Post ##{post.id}: #{post.errors.full_messages.join(", ")}"
        end
      end
    end

    puts "\nMigrated #{posts_count} posts"

    # Migrate Blog post_footer_html to post_footer_content
    blogs_count = 0
    blogs_with_footer = Blog.where.not(post_footer_html: [nil, ""])
    total_blogs = blogs_with_footer.count

    puts "Found #{total_blogs} blogs with post_footer_html to migrate"

    blogs_with_footer.find_each do |blog|
      if blog.post_footer_content.blank? && blog.read_attribute(:post_footer_html).present?
        blog.post_footer_content = blog.read_attribute(:post_footer_html)
        if blog.save(validate: false)
          blogs_count += 1
          print "." if blogs_count % 10 == 0
        else
          puts "\nFailed to migrate Blog ##{blog.id}: #{blog.errors.full_messages.join(", ")}"
        end
      end
    end

    puts "\nMigrated #{blogs_count} blog footers"
    puts "Migration complete!"
  end

  desc "Verify ActionText migration"
  task verify_migration: :environment do
    puts "Verifying ActionText migration..."

    # Check Posts
    posts_with_html = Post.where.not(body_html: [nil, ""])
    posts_without_action_text = posts_with_html.select { |p| p.body_content.blank? }

    if posts_without_action_text.any?
      puts "WARNING: #{posts_without_action_text.count} posts have body_html but no body_content"
      posts_without_action_text.first(5).each do |post|
        puts "  - Post ##{post.id}: #{post.title}"
      end
    else
      puts "✓ All posts with body_html have been migrated to body_content"
    end

    # Check Blogs
    blogs_with_html = Blog.where.not(post_footer_html: [nil, ""])
    blogs_without_action_text = blogs_with_html.select { |b| b.post_footer_content.blank? }

    if blogs_without_action_text.any?
      puts "WARNING: #{blogs_without_action_text.count} blogs have post_footer_html but no post_footer_content"
      blogs_without_action_text.first(5).each do |blog|
        puts "  - Blog ##{blog.id}: #{blog.subdomain || blog.custom_domain}"
      end
    else
      puts "✓ All blogs with post_footer_html have been migrated to post_footer_content"
    end

    puts "Verification complete!"
  end
end
