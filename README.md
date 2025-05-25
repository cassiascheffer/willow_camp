# Willow Camp

Willow Camp is a minimalist blogging platform built with Ruby on Rails and styled with a customizable theme system supporting Tokyo Night and Solarized color schemes.

## Features

- Clean, responsive blog post interface
- Multi-theme system with Tokyo Night and Solarized themes
- Dark/light mode support
- Markdown post content with YAML frontmatter support
- Pagination
- SEO-friendly URLs

## Development Setup

### Prerequisites

- Ruby 3.2.0+
- Node.js 18+
- PostgreSQL 14+
- Yarn or npm

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/willow_camp.git
cd willow_camp
```

2. Install dependencies:
```bash
bundle install
```

3. Setup database:
```bash
rails db:setup
```

4. Start development servers:
```bash
# In one terminal:
bin/dev
```

5. Visit http://localhost:3000

### Theme Customization

The theme system is configured in `app/assets/tailwind/application.css`. To switch between themes:

1. Change the `--theme` CSS variable to either `"tokyo"` or `"solarized"`
2. Set `data-theme` attribute on the root element to match

### Testing

Run the test suite with:

```bash
rails test
```

## Markdown and Frontmatter

Willow Camp supports Markdown with YAML frontmatter for post content. The frontmatter allows you to specify post metadata like title, description, tags, and publication status.

### Frontmatter Format

```yaml
---
title: My Awesome Post
description: This is a great post about Ruby on Rails
published: true
date: 2023-05-25
tags:
  - rails
  - ruby
  - web
---

# Post content starts here

Regular markdown content...
```

### Creating Posts from Markdown Files

You can programmatically create posts from markdown files using the `BuildPostFromMd` service:

```ruby
# Read markdown file
markdown_content = File.read("path/to/post.md")

# Create post for a specific author
author = User.find_by(email: "author@example.com")
post = Post.from_markdown(markdown_content, author)

# Save the post
post.save
```

## Deployment

The application is designed to be deployed to any standard Rails hosting platform like Heroku, Fly.io, or Railway.

Standard deployment commands:

```bash
rails assets:precompile
rails db:migrate
```
