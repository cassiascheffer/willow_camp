# ⛺ [willow.camp](https://willow.camp)

[![Status](https://img.shields.io/badge/status-page-brightgreen)](https://status.willow.camp/)

A blogging platform built with Ruby on Rails. Supports subdomains, custom domains, multiple themes, and markdown posts.

## Features

- Blog post interface with pagination
- DaisyUI theme picker
- Markdown posts with YAML frontmatter
- API for post management
- CLI for post management (see `cli/` directory)

## Development Setup

### Prerequisites

- Ruby 3.2.0+
- Node.js 18+
- PostgreSQL 14+
- Yarn or npm

### Installation

1. Clone the repository:
```bash
git clone https://github.com/cassiascheffer/willow_camp.git
cd willow_camp
```

### CLI Development

The CLI is located in the `cli/` directory:

```bash
cd cli
bundle install
bundle exec rake test
gem build willow_camp_cli.gemspec
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
bin/dev
```

5. Visit http://localhost:3000

### Theme Configuration

Themes can be changed in the settings page. The application supports all DaisyUI themes.

### Testing

```bash
rails test
```

## API Documentation

The API uses token-based authentication and returns JSON responses.

### Authentication

Include a bearer token in requests:

```
Authorization: Bearer your-api-token
```

Create tokens in the dashboard at `/dashboard/settings`.

### Endpoints

#### List Posts

```
GET /api/posts
```

Returns all posts for the authenticated user.

**Response:**
```json
{
  "posts": [
    {
      "id": 1,
      "slug": "my-post",
      "markdown": "---\ntitle: My Post\n---\n# Content"
    }
  ]
}
```

#### Get a Post

```
GET /api/posts/:slug
```

Returns a specific post by slug.

#### Create a Post

```
POST /api/posts
```

**Request:**
```json
{
  "post": {
    "markdown": "---\ntitle: My New Post\npublished: true\n---\n# Content"
  }
}
```

#### Update a Post

```
PATCH /api/posts/:slug
```

**Request:**
```json
{
  "post": {
    "markdown": "---\ntitle: Updated Title\n---\n# Updated content"
  }
}
```

#### Delete a Post

```
DELETE /api/posts/:slug
```

Returns 204 on success.

### Error Responses

- **401**: `{ "error": "Unauthorized" }`
- **403**: `{ "error": "You don't have permission to access this post" }`
- **404**: `{ "error": "Post not found" }`
- **422**: `{ "errors": ["Title can't be blank"] }`

### Example Usage

```bash
curl -X POST https://willow.camp/api/posts \
  -H "Authorization: Bearer your-api-token" \
  -H "Content-Type: application/json" \
  -d '{
    "post": {
      "markdown": "---\ntitle: API Post\n---\n# Hello World"
    }
  }'
```

## Markdown Posts

Posts use Markdown with YAML frontmatter:

```yaml
---
title: My Post
description: Post description
published: true
date: 2023-05-25
tags:
  - rails
  - ruby
---

# Post content

Regular markdown content here.
```

### Creating Posts from Files

```ruby
markdown_content = File.read("path/to/post.md")
author = User.find_by(email: "author@example.com")
post = Post.from_markdown(markdown_content, author)
post.save
```

## Deployment

Deploy to any Rails hosting platform (Heroku, Fly.io, Railway).

```bash
rails assets:precompile
rails db:migrate
```

## License

**This license applies to the willow.camp software only, not to any content created using the software.**

[willow.camp](https://github.com/cassiascheffer/willow_camp) by [Cassia Scheffer](https://github.com/cassiascheffer) software is licensed under a [Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License](https://creativecommons.org/licenses/by-nc-sa/4.0/).

[![CC BY-NC-SA 4.0](https://licensebuttons.net/l/by-nc-sa/4.0/88x31.png)](https://creativecommons.org/licenses/by-nc-sa/4.0/)

**Note:** Content created by users of willow.camp (blog posts, images, etc.) remains the property of the respective content creators and is not covered by this license.
