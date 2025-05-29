# Willow Camp

Willow Camp is a minimalist blogging platform built with Ruby on Rails and styled with a customizable theme system supporting Tokyo Night and Solarized color schemes.

## Features

- Clean, responsive blog post interface
- Multi-theme system with Tokyo Night and Solarized themes
- Dark/light mode support
- Markdown post content with YAML frontmatter support
- Pagination
- SEO-friendly URLs
- RESTful API for post management

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

## API Documentation

Willow Camp provides a RESTful API for managing blog posts programmatically. The API uses token-based authentication and returns JSON responses.

### Authentication

All API endpoints require authentication using a bearer token:

```
Authorization: Bearer your-api-token
```

Tokens can be created and managed through the dashboard at `/dashboard/settings`.

### Endpoints

#### List Posts

```
GET /api/posts
```

Returns all posts belonging to the authenticated user.

**Response Format:**
```json
{
  "posts": [
    {
      "id": 1,
      "slug": "my-awesome-post",
      "markdown": "---\ntitle: My Awesome Post\n---\n# Content"
    },
    {
      "id": 2,
      "slug": "another-post",
      "markdown": "---\ntitle: Another Post\n---\n# Content"
    }
  ]
}
```

#### Get a Post

```
GET /api/posts/:slug
```

Returns a specific post by its slug.

**Response Format:**
```json
{
  "post": {
    "id": 1,
    "slug": "my-awesome-post",
    "markdown": "---\ntitle: My Awesome Post\n---\n# Content"
  }
}
```

#### Create a Post

```
POST /api/posts
```

Creates a new post.

**Request Format:**
```json
{
  "post": {
    "markdown": "---\ntitle: My New Post\npublished: true\nmeta_description: A brief description\ntags:\n  - ruby\n  - rails\n---\n# Post Content\n\nMarkdown content here..."
  }
}
```

**Response Format:**
```json
{
  "post": {
    "id": 3,
    "slug": "my-new-post",
    "title": "My New Post",
    "published": true,
    "meta_description": "A brief description",
    "published_at": "2025-05-25T12:00:00Z",
    "tag_list": ["ruby", "rails"],
    "markdown": "---\ntitle: My New Post\n---\n# Post Content"
  }
}
```

#### Update a Post

```
PATCH /api/posts/:slug
```

Updates an existing post.

**Request Format:**
```json
{
  "post": {
    "markdown": "---\ntitle: Updated Post Title\npublished: true\n---\n# Updated Content"
  }
}
```

**Response Format:**
```json
{
  "post": {
    "id": 1,
    "slug": "my-awesome-post",
    "title": "Updated Post Title",
    "published": true,
    "meta_description": null,
    "published_at": "2025-05-25T12:00:00Z",
    "tag_list": [],
    "markdown": "---\ntitle: Updated Post Title\n---\n# Updated Content"
  }
}
```

#### Delete a Post

```
DELETE /api/posts/:slug
```

Deletes a post. Returns no content (204) on success.

### Error Handling

The API returns appropriate HTTP status codes and error messages:

- **401 Unauthorized**: Missing or invalid authentication token
  ```json
  { "error": "Unauthorized" }
  ```

- **403 Forbidden**: Attempting to access another user's post
  ```json
  { "error": "You don't have permission to access this post" }
  ```

- **404 Not Found**: Post does not exist
  ```json
  { "error": "Post not found" }
  ```

- **422 Unprocessable Entity**: Validation errors
  ```json
  { "errors": ["Title can't be blank"] }
  ```

### Example Usage

Using cURL to create a new post:

```bash
curl -X POST https://yourblog.example.com/api/posts \
  -H "Authorization: Bearer your-api-token" \
  -H "Content-Type: application/json" \
  -d '{
    "post": {
      "markdown": "---\ntitle: API Created Post\npublished: true\n---\n# Hello World\n\nThis post was created via the API."
    }
  }'
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
