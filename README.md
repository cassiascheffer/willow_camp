# ⛺ willow.camp

A blogging platform built with Ruby on Rails. Supports subdomains, custom domains, multiple themes, and markdown posts.

## Features

- Blog post interface with pagination
- DaisyUI theme picker
- Markdown posts with YAML frontmatter
- API for post management
- CLI for post management: [@cassiascheffer/willow_camp_cli](https://github.com/cassiascheffer/willow_camp_cli)

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
