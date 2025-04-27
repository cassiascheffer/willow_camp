# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

users = [
  { email_address: "winter@acorn.com", password: "winter", subdomain: "winter" },
  { email_address: "willow@acorn.com", password: "willow", subdomain: "willow" }
]

users.each do |user|
  user = User.find_or_create_by!(email_address: user[:email_address]) do |u|
    u.password = user[:password]
    u.subdomain = user[:subdomain]
  end

  25.times do
    user.posts.find_or_create_by!(slug: Faker::Internet.slug) do |post|
      post.body = Faker::Lorem.paragraphs(number: Faker::Number.number(digits: 2)).join("\n\n")
      post.title = Faker::Book.title
      post.published = Faker::Boolean.boolean
      post.published_at = Faker::Date.between(from: 2.days.ago, to: Date.today)
    end
  end
end
