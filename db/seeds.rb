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

puts "=== Seeding database with blogs and posts ==="

User.destroy_all
Blog.destroy_all

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
  # Create User
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
    b.no_index = false
  end
  puts "Created blog: #{blog.title} with subdomain: #{blog.subdomain}"

  # Create posts associated with both user and blog
  100.times do |i|
    # Every post gets a mermaid diagram
    diagram_type = i % 5

    body_content = case diagram_type
    when 0
      # Flowchart
      <<~MARKDOWN
        #{Faker::Lorem.paragraph(sentence_count: 3)}

        ## #{["Process Flow", "Workflow", "Decision Tree", "System Flow"].sample}

        ```mermaid
        graph TD
            A[#{Faker::Lorem.word.capitalize}] --> B{#{Faker::Lorem.question}}
            B -->|Yes| C[#{Faker::Lorem.words(number: 2).join(" ").capitalize}]
            B -->|No| D[#{Faker::Lorem.words(number: 2).join(" ").capitalize}]
            C --> E[Complete]
            D --> F[Review]
            F --> B
        ```

        #{Faker::Markdown.sandwich(sentences: 6, repeat: 2)}
      MARKDOWN
    when 1
      # Sequence diagram
      <<~MARKDOWN
        #{Faker::Lorem.paragraph(sentence_count: 2)}

        ## #{["System Architecture", "API Flow", "User Journey", "Data Flow"].sample}

        ```mermaid
        sequenceDiagram
            participant Client
            participant Server
            participant Database
            participant Cache
            Client->>Server: #{Faker::Lorem.words(number: 2).join(" ").capitalize}
            Server->>Cache: Check Cache
            Cache-->>Server: #{["Cache Miss", "Cache Hit"].sample}
            Server->>Database: Query Data
            Database-->>Server: Return Results
            Server->>Cache: Update Cache
            Server-->>Client: Response
        ```

        #{Faker::Markdown.sandwich(sentences: 4, repeat: 3)}
      MARKDOWN
    when 2
      # Pie chart
      <<~MARKDOWN
        #{Faker::Lorem.paragraph(sentence_count: 2)}

        ## #{["Statistics", "Distribution", "Analysis", "Breakdown"].sample}

        ```mermaid
        pie title #{Faker::Lorem.words(number: 2).join(" ").capitalize}
            "#{Faker::Lorem.word.capitalize}" : #{rand(10..40)}
            "#{Faker::Lorem.word.capitalize}" : #{rand(10..30)}
            "#{Faker::Lorem.word.capitalize}" : #{rand(10..25)}
            "#{Faker::Lorem.word.capitalize}" : #{rand(5..20)}
            "Other" : #{rand(5..15)}
        ```

        #{Faker::Markdown.sandwich(sentences: 5, repeat: 2)}
      MARKDOWN
    when 3
      # Gantt chart
      <<~MARKDOWN
        #{Faker::Lorem.paragraph(sentence_count: 2)}

        ## #{["Project Timeline", "Schedule", "Roadmap", "Development Plan"].sample}

        ```mermaid
        gantt
            title #{Faker::Lorem.words(number: 3).join(" ").capitalize}
            dateFormat  YYYY-MM-DD
            section Phase 1
            Task A           :2024-01-01, 30d
            Task B           :after Task A, 20d
            section Phase 2
            Task C           :2024-02-15, 25d
            Task D           :after Task C, 15d
            section Phase 3
            Task E           :2024-03-20, 35d
        ```

        #{Faker::Markdown.sandwich(sentences: 4, repeat: 2)}
      MARKDOWN
    when 4
      # State diagram
      <<~MARKDOWN
        #{Faker::Lorem.paragraph(sentence_count: 3)}

        ## #{["State Machine", "Status Flow", "Lifecycle", "State Transitions"].sample}

        ```mermaid
        stateDiagram-v2
            [*] --> Draft
            Draft --> Review: Submit
            Review --> Approved: Approve
            Review --> Draft: Reject
            Approved --> Published: Publish
            Published --> Archived: Archive
            Archived --> [*]
        ```

        #{Faker::Markdown.sandwich(sentences: 5, repeat: 2)}
      MARKDOWN
    end

    blog.posts.create! do |post|
      post.title = Faker::Books::Lovecraft.tome
      post.body_markdown = body_content
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
  puts "Created 100 posts for blog: #{blog.title} (3 featured, all with mermaid diagrams)"
end

# rubocop:enable Rails/Output
