# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

User.destroy_all

users = [
  {email_address: "winter@acorn.ca", password: "winter", subdomain: "winter", name: "Winter Solstice"},
  {email_address: "willow@acorn.ca", password: "willow", subdomain: "willow", name: "Will-o-the-Whisp"}
]

users.each do |user|
  user = User.find_or_create_by!(email_address: user[:email_address]) do |u|
    u.password = user[:password]
    u.subdomain = user[:subdomain]
  end
  puts "Created user: #{user.email_address} with subdomain: #{user.subdomain}"

  100.times do
    user.posts.create! do |post|
      post.title = Faker::Books::Lovecraft.tome
      post.body_markdown = Faker::Markdown.sandwich(sentences: 6, repeat: 3)
      post.published = Faker::Boolean.boolean
      post.published_at = Faker::Date.between(from: 2.days.ago, to: Date.today)
      post.tag_list = ["dogs", "cats", "fun!"]
    end
    print "."
  end
  puts ""
  puts "Created 100 posts for user: #{user.email_address}"
end
