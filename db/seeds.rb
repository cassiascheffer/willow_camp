# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# rubocop:disable Rails/Output

# Support both single-blog (old format) and multi-blog (new format) seeding
# Use SINGLE_BLOG=true rails db:seed for old format (commit 290f2372)
# Use rails db:seed for new multi-blog format
single_blog_mode = ENV["SINGLE_BLOG"] == "true"

if single_blog_mode
  puts "=== Running in SINGLE BLOG mode (old format) ==="
  puts "Seeding user fields directly without blogs table"
else
  puts "=== Running in MULTI BLOG mode (new format) ==="
  puts "Seeding with separate blogs table"
end

User.destroy_all
Blog.destroy_all unless single_blog_mode

users = [
  {
    email: "winter@acorn.ca",
    password: "winter",
    subdomain: "winter",
    name: "Winter Solstice",
    blog_title: "Winter's Tales",
    slug: "winter-solstice",
    site_meta_description: "Winter's thoughts and tales",
    favicon_emoji: "❄️",
    theme: "winter"
  },
  {
    email: "willow@acorn.ca",
    password: "willow",
    subdomain: "willow",
    name: "Will-o-the-Whisp",
    blog_title: "Willow's Whispers",
    slug: "will-o-the-whisp",
    site_meta_description: "Whispers from the willow tree",
    favicon_emoji: "🌳",
    theme: "forest"
  }
]

users.each do |user_data|
  if single_blog_mode
    # Old format: blog fields directly on User model
    user = User.find_or_create_by!(email: user_data[:email]) do |u|
      u.password = user_data[:password]
      u.name = user_data[:name]
      # Blog fields that existed on User model in old format
      u.subdomain = user_data[:subdomain]
      u.blog_title = user_data[:blog_title]
      u.slug = user_data[:slug]
      u.site_meta_description = user_data[:site_meta_description]
      u.favicon_emoji = user_data[:favicon_emoji]
      u.theme = user_data[:theme]
      u.custom_domain = nil
      u.post_footer_markdown = nil
      u.post_footer_html = nil
      u.no_index = false
    end
    puts "Created user: #{user.email} with blog fields (subdomain: #{user.subdomain})"

    # Create posts associated directly with user (no blog_id)
    100.times do |i|
      user.posts.create! do |post|
        post.title = Faker::Books::Lovecraft.tome
        post.body_markdown = Faker::Markdown.sandwich(sentences: 6, repeat: 3)
        post.published = Faker::Boolean.boolean
        post.published_at = Faker::Date.between(from: 2.days.ago, to: Time.zone.today)
        post.tag_list = ["dogs", "cats", "fun!"]
        post.featured = i < 3 # First 3 posts are featured
        post.meta_description = Faker::Lorem.sentence(word_count: 12, supplemental: true, random_words_to_add: 8) if Faker::Boolean.boolean(true_ratio: 0.7)
        # No blog_id in old format
      end
      print "."
    end
    puts ""
    puts "Created 100 posts for user: #{user.name} (3 featured)"
  else
    # New format: separate User and Blog models
    user = User.find_or_create_by!(email: user_data[:email]) do |u|
      u.password = user_data[:password]
      u.name = user_data[:name]
    end
    puts "Created user: #{user.email}"

    # Create primary blog for the user
    blog = user.blogs.find_or_create_by!(subdomain: user_data[:subdomain]) do |b|
      b.title = user_data[:blog_title]
      b.slug = user_data[:slug]
      b.meta_description = user_data[:site_meta_description]
      b.favicon_emoji = user_data[:favicon_emoji]
      b.theme = user_data[:theme]
      b.primary = true
      b.custom_domain = nil
      b.post_footer_markdown = nil
      b.post_footer_html = nil
      b.no_index = false
    end
    puts "Created blog: #{blog.title} with subdomain: #{blog.subdomain}"

    # Create posts associated with both user and blog
    100.times do |i|
      blog.posts.create! do |post|
        post.title = Faker::Books::Lovecraft.tome
        post.body_markdown = Faker::Markdown.sandwich(sentences: 6, repeat: 3)
        post.published = Faker::Boolean.boolean
        post.published_at = Faker::Date.between(from: 2.days.ago, to: Time.zone.today)
        post.tag_list = ["dogs", "cats", "fun!"]
        post.featured = i < 3 # First 3 posts are featured
        post.meta_description = Faker::Lorem.sentence(word_count: 12, supplemental: true, random_words_to_add: 8) if Faker::Boolean.boolean(true_ratio: 0.7)
        post.author = user
      end
      print "."
    end
    puts ""
    puts "Created 100 posts for blog: #{blog.title} (3 featured)"
  end
end

# rubocop:enable Rails/Output
