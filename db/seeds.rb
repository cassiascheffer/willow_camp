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
User.destroy_all
Blog.destroy_all

users = [
  {email: "winter@acorn.ca", password: "winter", subdomain: "winter", name: "Winter Solstice", blog_title: "Winter's Tales"},
  {email: "willow@acorn.ca", password: "willow", subdomain: "willow", name: "Will-o-the-Whisp", blog_title: "Willow's Whispers"}
]

users.each do |user_data|
  user = User.find_or_create_by!(email: user_data[:email]) do |u|
    u.password = user_data[:password]
    u.name = user_data[:name]
  end
  puts "Created user: #{user.email}"

  # Create primary blog for the user
  blog = user.blogs.find_or_create_by!(subdomain: user_data[:subdomain]) do |b|
    b.title = user_data[:blog_title]
    b.primary = true
    b.favicon_emoji = "📝"
  end
  puts "Created blog: #{blog.title} with subdomain: #{blog.subdomain}"

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

# rubocop:enable Rails/Output
